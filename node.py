# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Copyright (C) 2016 Daniel Zozin <daniel.zozin@posteo.net>


from fsmNode import FSMNode
from event import Event
from events import Events
from packet import Packet


class Node(FSMNode):
    """
    This class implements a node capable of communicating with other devices
    """

    # list of possible states for this node
    IDLE = 0
    TX = 1
    RX = 2
    PROC = 3
    SENSE = 4

    def __init__(self, config, channel, x, y):
        """
        Constructor.
        :param config: the set of configs loaded by the simulator
        :param channel: the channel to which frames are sent
        :param x: x position
        :param y: y position
        """
        FSMNode.__init__(self, config, channel, x, y)

        # Initialize the Finite State Machine with the transition table
        self.set_transitions(Node.IDLE, {
            # Try transmitting when a new packed is enqueued
            (Node.IDLE, Events.PACKET_ENQUEUED): self.try_transmitting,

            # The node is busy, do nothing with the newly enqueued packet
            (Node.RX, Events.PACKET_ENQUEUED): self.stay,
            (Node.PROC, Events.PACKET_ENQUEUED): self.stay,
            (Node.TX, Events.PACKET_ENQUEUED): self.stay,
            (Node.SENSE, Events.PACKET_ENQUEUED): self.stay,

            # Try receiving a packet in the air
            (Node.IDLE, Events.START_RX): self.try_receiving,

            # Set the receiving packet as corrupted by another one
            (Node.RX, Events.START_RX): self.corrupt_reception,

            # The node is busy, new packets detected in the air are dropped
            (Node.PROC, Events.START_RX): self.drop_receiving,
            (Node.TX, Events.START_RX): self.drop_receiving,
            (Node.SENSE, Events.START_RX): self.drop_receiving,

            # Detect the termination of a packet in the air and
            # remain in the same state
            (Node.IDLE, Events.END_RX): self.end_packet,
            (Node.PROC, Events.END_RX): self.end_packet,
            (Node.TX, Events.END_RX): self.end_packet,

            # Retry transmitting when a packet in the air terminates
            (Node.SENSE, Events.END_RX): self.retry_transmitting,

            # Start processing after reception
            (Node.RX, Events.END_RX): self.end_receiving,

            # Start processing after transmission
            (Node.TX, Events.END_TX): self.switch_to_proc,

            # Resume after processing terminates
            (Node.PROC, Events.END_PROC): self.resume_operations
        })

        # current packet being received
        self.current_rcv = None

        # count packets currently detected on channel
        self.packets_on_ch = 0

    def try_transmitting(self, event=None):
        """
        If the channel is not free go in SENSE state,
        otherwise start transmitting a packet (from the queue)
        """

        if(not self.is_channel_free()):
            return Node.SENSE

        self.transmit()
        return Node.TX

    def retry_transmitting(self, event=None):
        self.sense_packet_end()

        return self.try_transmitting()

    def try_receiving(self, event):
        was_channel_free = self.is_channel_free()

        # count new packet in the channel
        self.sense_packet_start()

        new_packet = event.get_obj()

        # If there are other packets on the channel, they will interfere with
        # this one, so set it to corrupted and don't try to receive it
        if not was_channel_free:
            new_packet.set_state(Packet.PKT_CORRUPTED)
            return FSMNode.STAY

        # Start receiving this packet
        self.current_rcv = new_packet
        self.current_rcv.set_state(Packet.PKT_RECEIVING)
        return Node.RX

    def corrupt_reception(self, event):
        # count new packet in the channel
        self.sense_packet_start()

        # the packet we are currently receiving is corrupted by a
        # collision with the new packet
        self.current_rcv.set_state(Packet.PKT_CORRUPTED)

        # Also the new packet is corrupted
        new_packet = event.get_obj()
        new_packet.set_state(Packet.PKT_CORRUPTED)

        # Stay anyway in RX until the end event
        return FSMNode.STAY

    def drop_receiving(self, event):
        # count new packet in the channel
        self.sense_packet_start()

        # If the node is not in IDLE or RX, it is not able to decode a new
        # packet so just ignore it and remain in same state
        return FSMNode.STAY

    def end_receiving(self, event):
        # count packet not in the channel anymore
        self.sense_packet_end()

        packet = event.get_obj()

        # The packet is the one under reception
        if packet.get_id() == self.current_rcv.get_id():
            # the packet is not corrupted, so it is successfully received
            if packet.get_state() == Packet.PKT_RECEIVING:
                packet.set_state(Packet.PKT_RECEIVED)

            self.logger.log_packet(event.get_source(), self, packet)

            # End reception and process packet (Even though it was corrupted)
            return self.switch_to_proc(event)

        # The packet is not the one under reception, so it should have
        # already been marked as corrupted on its start event
        assert(packet.get_state() == Packet.PKT_CORRUPTED)

        # Just log it and stay in the same state
        self.logger.log_packet(event.get_source(), self, packet)
        return FSMNode.STAY

    def end_packet(self, event):
        # count packet not in the channel anymore and stay in the same state
        self.sense_packet_end()

        return FSMNode.STAY

    def switch_to_proc(self, event):
        """
        Switches to the processing state and schedules the end_proc event
        """

        proc_time = self.proc_time.get_value()
        proc = Event(self.sim.get_time() + proc_time, Events.END_PROC, self,
                     self)
        self.sim.schedule_event(proc)
        return Node.PROC

    def resume_operations(self, event):
        """
        Handles the end of the processing period, resuming operations
        """
        if len(self.queue) == 0:
            # resuming operations but nothing to transmit. back to
            # IDLE
            return Node.IDLE
        else:
            # there is a packet ready in the queue, try transmitting it
            return self.try_transmitting()

    def is_channel_free(self):
        return self.packets_on_ch == 0

    def sense_packet_start(self):
        self.packets_on_ch = self.packets_on_ch + 1

    def sense_packet_end(self):
        self.packets_on_ch = self.packets_on_ch - 1
