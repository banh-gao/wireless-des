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
# Copyright (C) 2016 Daniel Zozin <zdenial@gmx.com>


class FSM:
    """
    Implement a Finite State Machine initialized with a transition table that
    maps pairs (State, Event) to an action and an event transition.

    For internal state S0 and event E0 there is a transition function T such
    that T:(S0, E0) -> S1 changes the internal state to S1.
    To avoid an anti-pattern the current state is not accessible from within
    a transition function.
    """
    def __init__(self, initialState, transitions):
        """
        :param initialState: The state the FSM has to start from
        :param transitions: A dictionary that maps pairs (State, Event) to a
        transition function. The transition function is defined as t(E) -> E
        where E is the event to handle.
        The FSM will move to the state returned by the function.
        If the function returns None, the FSM remains in the same state.
        """
        self.state = initialState
        self.transitions = transitions

    def handle_event(self, event):
        """
        Handles the given event with a mapped transition function.
        If there is no mapping an exeception will be raised.
        :param event: the event to handle
        """
        key = (self.state, event.get_type())

        if key not in self.transitions.keys():
            raise AssertionError("Unhandled event %s in state %s" %
                                 (event.get_type(), self.state))

        action = self.transitions[key]

        nextState = action(event)

        if(nextState is not None):
            self.state = nextState

        return self.state
