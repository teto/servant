{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PolyKinds         #-}
{-# LANGUAGE TypeFamilies      #-}
{-# LANGUAGE TypeOperators     #-}

import           Prelude ()
import           Prelude.Compat

import           Data.Aeson
import           Data.Proxy
import           Data.Text
import           GHC.Generics
import           Network.Wai
import           Network.Wai.Handler.Warp

import           Servant
import           Servant.Server.Generic (AsServer, genericServeT, genericServer, genericServe)
import           Servant.API.Generic

-- * Example

-- | A greet message data type
newtype Greet = Greet { _msg :: Text }
  deriving (Generic, Show)

instance FromJSON Greet
instance ToJSON Greet

-- API specification
-- type TestApi =
--        -- GET /hello/:name?capital={true, false}  returns a Greet as JSON
--        "hello" :> Capture "name" Text :> QueryParam "capital" Bool :> Get '[JSON] Greet

--        -- POST /greet with a Greet as JSON in the request body,
--        --             returns a Greet as JSON
--   :<|> "greet" :> ReqBody '[JSON] Greet :> Post '[JSON] Greet

--        -- DELETE /greet/:greetid
--   :<|> "greet" :> Capture "greetid" Text :> Delete '[JSON] NoContent

--   :<|> NamedRoutes OtherRoutes

data TestRoutes mode = TestRoutes
  { hello :: mode :- "hello" :> Capture "name" Text :> QueryParam "capital" Bool :> Get '[JSON] Greet
  , greet :: mode :- "greet" :> ReqBody '[JSON] Greet :> Post '[JSON] Greet
  , other :: OtherRoutes mode
  }
  deriving Generic

data OtherRoutes mode = OtherRoutes
  { version :: mode :- Get '[JSON] Int
  , bye :: mode :- "bye" :> Capture "name" Text :> Get '[JSON] Text
  }
  deriving Generic

otherRoutes :: OtherRoutes AsServer
otherRoutes = OtherRoutes {
      version = pure 42
    , bye = \name -> pure $ "Bye, " <> name <> " !"

  }

-- resultStoreApi, storeAPI :: Proxy (ToServantApi ResultStoreAPI)
-- resultStoreApi = genericApi (Proxy :: Proxy ResultStoreAPI)
testApi :: Proxy (ToServantApi TestRoutes)
testApi = genericApi (Proxy :: Proxy TestRoutes)

testRoutes :: TestRoutes AsServer
testRoutes = TestRoutes {
        hello = helloH
      , greet = \greetMsg  -> return greetMsg
      , other = otherRoutes
      }
      where
        helloH name Nothing = helloH name (Just False)
        helloH name (Just False) = return . Greet $ "Hello, " <> name
        helloH name (Just True) = return . Greet . toUpper $ "Hello, " <> name


-- Turn the server into a WAI app. 'serve' is provided by servant,
-- more precisely by the Servant.Server module.
test :: Application
test = genericServe testRoutes

-- Run the server.
--
-- 'run' comes from Network.Wai.Handler.Warp
runTestServer :: Port -> IO ()
runTestServer port = run port test

-- Put this all to work!
main :: IO ()
main = runTestServer 8001

