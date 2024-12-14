module Main (main) where

import FiniteStateMachine
import qualified Data.Text as T

main :: IO ()
main = putStrLn $ T.unpack (generateDot liftModel)
