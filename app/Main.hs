module Main where

import Lib

import Control.Monad.IO.Class (liftIO)
import Data.Default (def)
import Text.Pandoc
import Text.Pandoc.PDF
import System.Environment (getArgs)
import qualified Data.ByteString as B
import qualified Data.ByteString.Lazy as BL
import qualified Data.Text as T

extractFirstArg :: [String] -> IO String
extractFirstArg [] = error "No arguments provided"
extractFirstArg (x:_) = pure x

main :: IO ()
main = do
  templRaw <- runIO (getTemplate "template.html") >>= handleError
  Right templ <- compileTemplate "" templRaw :: IO (Either String (Template T.Text))
  chatsPath <- getArgs >>= extractFirstArg
  chats <- B.readFile chatsPath
  -- TODO: refactor, skip unnecesary parsing
  parsed <- either (error . errorMsg) pure (parseMessages chats)
  let doc = createDocument $ parsed
  pdf <- runIO (makePDF "wkhtmltopdf" [] writeHtml5String
                (def {writerTemplate = Just templ}) doc) >>= handleError
  case pdf of Right b -> BL.writeFile "out.pdf" b
              Left e -> print e
