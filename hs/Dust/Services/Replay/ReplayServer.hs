import System.IO
import qualified Data.ByteString as B
import Data.ByteString.Char8 (pack)
import Data.Serialize
import Text.Printf (printf)
import Data.List as L
import Control.Concurrent
import Network.Socket (Socket, PortNumber(..))
import Network.Socket.ByteString (recv, sendAll)
import System.Entropy
import Data.Word (Word16)
import Network.Pcap
import System.Environment (getArgs)

import Dust.Model.Port
import Dust.Model.TrafficModel
import qualified Dust.Network.TcpServer as TCP
import qualified Dust.Network.UdpServer as UDP
import Dust.Model.Observations (loadObservations, makeModel)
import Dust.Services.Replay.Replay

main :: IO()
main = do
    args <- getArgs

    case args of
        (pcappath:protocol:port:maskfile:_) -> do
          mask <- loadMask maskfile
          replayServer pcappath protocol port mask
        (pcappath:protocol:port:_) -> replayServer pcappath protocol port (PacketMask [])
        otherwise      -> putStrLn "Usage: replay-server [pcap-file] [tcp|udp] [port] <mask-file>"

replayServer :: FilePath -> String -> String -> PacketMask -> IO()
replayServer pcappath protocol rport mask = do
    let host = "166.78.129.122"
    let port = PortNum 2013

    case protocol of
      "tcp" -> do
          let config = TCPConfig rport True
          pcap <- openPcap pcappath config
          TCP.server host port (replayStream config pcap mask)
      "udp" -> do
          let config = UDPConfig rport True host True
          pcap <- openPcap pcappath config
          UDP.server host port (replayStream config pcap mask)
      otherwise -> putStrLn $ "Unknown protocol " ++ protocol


