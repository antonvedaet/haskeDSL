{-# LANGUAGE GADTs #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}

module FiniteStateMachine where

import Control.Monad.Free
import Data.Text (Text)
import qualified Data.Text as T

data FSMCommand next where
    State :: Text -> next -> FSMCommand next
    Transition :: Text -> Text -> Text -> next -> FSMCommand next
    StartState :: Text -> next -> FSMCommand next
    EndState :: Text -> next -> FSMCommand next
    Ignore :: Text -> Text -> next -> FSMCommand next

instance Functor FSMCommand where
    fmap f (State name next) = State name (f next)
    fmap f (Transition from label to next) = Transition from label to (f next)
    fmap f (StartState name next) = StartState name (f next)
    fmap f (EndState name next) = EndState name (f next)
    fmap f (Ignore from to next) = Ignore from to (f next)

type FSM = Free FSMCommand


state :: Text -> FSM ()
state name = liftF $ State name ()

transition :: Text -> Text -> Text -> FSM ()
transition from label to = liftF $ Transition from label to ()

startState :: Text -> FSM ()
startState name = liftF $ StartState name ()

endState :: Text -> FSM ()
endState name = liftF $ EndState name ()

ignore :: Text -> Text -> FSM ()
ignore from to = liftF $ Ignore from to ()

liftModel :: FSM ()
liftModel = do
    state "Idle"
    state "MovingUp"
    state "MovingDown"
    startState "Idle"
    endState "Idle"
    transition "Idle" "GoUp" "MovingUp"
    transition "MovingUp" "Stop" "Idle"
    transition "Idle" "GoDown" "MovingDown"
    transition "MovingDown" "Stop" "Idle"
    transition "Idle" "PickUp" "Idle"
    ignore "MovingUp" "PickUp"
    ignore "MovingDown" "PickUp"

generateDot :: FSM a -> Text
generateDot fsm = T.unlines $ "digraph FSM {" : map toDot (extractFSM fsm) ++ ["}"]
  where
    toDot (State name _) = T.concat ["  ", name, " [shape=circle];"]
    toDot (Transition from label to _) = T.concat ["  ", from, " -> ", to, " [label=\"", label, "\"];"]
    toDot (StartState name _) = T.concat ["  start -> ", name, ";"]
    toDot (EndState name _) = T.concat ["  ", name, " [shape=doublecircle];"]
    toDot (Ignore from to _) = T.concat ["  ", from, " -> ", to, " [style=dotted];"]
    toDot _ = ""

extractFSM :: FSM a -> [FSMCommand ()]
extractFSM (Free command) = case command of
    State name next -> State name () : extractFSM next
    Transition from label to next -> Transition from label to () : extractFSM next
    StartState name next -> StartState name () : extractFSM next
    EndState name next -> EndState name () : extractFSM next
    Ignore from to next -> Ignore from to () : extractFSM next
extractFSM (Pure _) = []
