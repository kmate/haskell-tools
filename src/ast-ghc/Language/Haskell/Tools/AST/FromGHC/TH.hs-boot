module Language.Haskell.Tools.AST.FromGHC.TH where

import SrcLoc as GHC
import RdrName as GHC
import HsTypes as GHC
import HsExpr as GHC
import Language.Haskell.Tools.AST.FromGHC.Monad
import Language.Haskell.Tools.AST.FromGHC.Utils
import Language.Haskell.Tools.AST.FromGHC.Base
import Language.Haskell.Tools.AST (Ann(..))
import qualified Language.Haskell.Tools.AST as AST

trfQuasiQuotation' :: TransformName n r => HsQuasiQuote n -> Trf (AST.QuasiQuote r)
trfSplice' :: TransformName n r => HsSplice n -> Trf (AST.Splice r)
trfBracket' :: TransformName n r => HsBracket n -> Trf (AST.Bracket r)
