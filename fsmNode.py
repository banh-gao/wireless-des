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

from module import Module
from distribution import Distribution
from packet import Packet
from event import Event
from events import Events


class FSMNode(Module):
    """
    Implement a Finite State Machine initialized with a transition table that
    maps pairs (State, Event) to an action and an event transition.

    For internal state S0 and event E0 there is a transition function T such
    that T:(S0, E0) -> S1 changes the internal state to S1.
    To avoid an anti-pattern the current state is not accessible from within
    a transition function.
    """

    # transmission speed parameter (bits per second)
    DATARATE = "datarate"
    # queue size
    QUEUE = "queue"
    # inter-arrival distribution (seconds)
    INTERARRIVAL = "interarrival"
    # packet size distribution (bytes)
    SIZE = "size"
    # processing time distribution (seconds)
    PROC_TIME = "processing"
    # max packet size (bytes)
    MAXSIZE = "maxsize"

    STAY = -1

    def __init__(self, config, channel, x, y):
        """
        :param initialState: The state the FSM has to start from
        :param transitions: A dictionary that maps pairs (State, Event) to a
        transition function. The transition function is defined as t(E) -> E
        where E is the event to handle.
        The FSM will move to the state returned by the function.
        If the function returns None, the FSM remains in the same state.
        """
        Module.__init__(self)

        # load configuration parameters
        self.datarate = config.get_param(FSMNode.DATARATE)
        self.queue_size = config.get_param(FSMNode.QUEUE)
        self.interarrival = Distribution(config.get_param(FSMNode.INTERARRIVAL))
        self.size = Distribution(config.get_param(FSMNode.SIZE))
        self.proc_time = Distribution(config.get_param(FSMNode.PROC_TIME))
        self.maxsize = config.get_param(FSMNode.MAXSIZE)

        # save position
        self.x = x
        self.y = y

        # save channel
        self.channel = channel

        # queue of packets to be sent
        self.queue = []

    def set_transitions(self, initialState, transitions):
        self.state = initialState
        self.transitions = transitions

    def initialize(self):
        """
        Initialization. Starts node operation by scheduling the first packet
        """
        self.schedule_next_arrival()

    def schedule_next_arrival(self):
        """
        Schedules a new arrival event
        """
        # extract random value for next arrival
        arrival = self.interarrival.get_value()

        # draw packet size from the distribution
        packet_size = self.size.get_value()

        # generate an event setting this node as destination
        event = Event(self.sim.get_time() + arrival, Events.PACKET_ARRIVAL,
                      self, self, packet_size)
        self.sim.schedule_event(event)

    def handle_event(self, event):
        """
        Handles the given event with a mapped transition function.
        If there is no mapping an exeception will be raised.
        :param event: the event to handle
        """

        # Log current state
        self.logger.log_state(self, self.state)

        # On arrival always try to enqueue and schedule next packet arrival
        if(event.get_type() == Events.PACKET_ARRIVAL):
            self.schedule_next_arrival()
            # If enqueue fails don't notify the node and remain in the
            # same state
            if(not self.enqueue_arrived(event)):
                return
            else:
                event = Event(event.get_time(), Events.PACKET_ENQUEUED,
                              event.get_destination(), event.get_source(),
                              event.get_obj())

        key = (self.state, event.get_type())

        if key not in self.transitions.keys():
            raise AssertionError("Unhandled event %s in state %s" %
                                 (event.get_type(), self.state))

        action = self.transitions[key]

        nextState = action(event)

        if(nextState is None):
            raise AssertionError("Unknown next state for transition"
                                 + " function %s" % action.__name__)

        if(nextState is not FSMNode.STAY):
            self.state = nextState

    def enqueue_arrived(self, event):
        packet_size = event.get_obj()
        self.logger.log_arrival(self, packet_size)

        if self.queue_size == 0 or len(self.queue) < self.queue_size:
            # if queue size is infinite or there is still space
            self.queue.append(packet_size)
            self.logger.log_queue_length(self, len(self.queue))
            return True
        else:
            # if there is no space left, we drop the packet and log
            self.logger.log_queue_drop(self, packet_size)
            return False

    def stay(self, event):
        return self.STAY

    def transmit(self):
        assert(len(self.queue) > 0)

        packet_size = self.queue.pop(0)
        self.logger.log_queue_length(self, len(self.queue))

        duration = packet_size * 8 / self.datarate
        # transmit packet
        packet = Packet(packet_size, duration)
        if(packet.get_id() == 19):
            pass
        self.channel.start_transmission(self, packet)
        # schedule end of transmission
        end_tx = Event(self.sim.get_time() + duration, Events.END_TX, self,
                       self, packet)
        self.sim.schedule_event(end_tx)

    def get_posx(self):
        """
        Returns x position
        :returns: x position in meters
        """
        return self.x

    def get_posy(self):
        """
        Returns y position
        :returns: y position in meters
        """
        return self.y
