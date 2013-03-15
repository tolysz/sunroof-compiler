{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE FlexibleContexts #-}
module Language.Sunroof.Concurrent
  ( loop
  , forkJS
  , threadDelay
  , yield
  ) where

import Language.Sunroof.Types
  ( JSA, JSB, JS
  , SunroofThread
  , function, continuation, goto, kast
  , apply, cast, nullJS, blockableJS
  , (#)
  , JSContinuation, JSFunction
  , liftJS, reifycc )
import Language.Sunroof.Classes ( Sunroof(..) )
import Language.Sunroof.JS.Ref ( newJSRef, readJSRef, writeJSRef, JSRef )
import Language.Sunroof.JS.Number ( JSNumber )
import Language.Sunroof.JS.Browser ( window, setTimeout )

-- -------------------------------------------------------------
-- General Concurrent Combinators.
-- -------------------------------------------------------------

-- | @loopJS x f@ executes the function @f@ repeatedly.
--   After each iteration the result value of the function
--   is feed back as input of the next iteration.
--   The initial value supplied for the first iteration is @x@.
--   This loop will never terminate.
loop :: forall a . (Sunroof a) => a -> (a -> JSB a) -> JSB ()
loop start m = do
  v :: JSRef (JSContinuation ()) <- newJSRef (cast nullJS)
  s <- newJSRef start
  f <- continuation $ \ () -> do
          a <- readJSRef s
          a' <- m a
          writeJSRef s a'
          f <- readJSRef v
          _ <- liftJS $ window # setTimeout f 0
          return ()
  writeJSRef v f
  goto f () -- and call the function
  return ()

forkJS :: (SunroofThread t1) => JS t1 () -> JS t2 ()
forkJS m = do
  f <- continuation $ \ () -> blockableJS m
  _ <- liftJS $ window # setTimeout f 0
  return ()

-- | Delay the execution of all instructions after this one by
--   the given amount of milliseconds.
threadDelay :: JSNumber -> JSB ()
threadDelay n = reifycc $ \ o -> do
  _ <- liftJS $ window # setTimeout o n
  return ()

-- | Give another thread time to execute.
yield :: JSB ()
yield = threadDelay 0













