{-# LANGUAGE LambdaCase
           , ViewPatterns
           #-}
module Language.Haskell.Tools.AST.FromGHC.Stmts where
 
import Data.Maybe
import Control.Monad.Reader

import SrcLoc as GHC
import RdrName as GHC
import HsTypes as GHC
import HsPat as GHC
import HsExpr as GHC
import ApiAnnotation as GHC

import Language.Haskell.Tools.AST.FromGHC.Base
import Language.Haskell.Tools.AST.FromGHC.Types
import {-# SOURCE #-} Language.Haskell.Tools.AST.FromGHC.Exprs
import Language.Haskell.Tools.AST.FromGHC.Patterns
import {-# SOURCE #-} Language.Haskell.Tools.AST.FromGHC.Binds
import Language.Haskell.Tools.AST.FromGHC.Monad
import Language.Haskell.Tools.AST.FromGHC.Utils

import Language.Haskell.Tools.AST (Ann(..), AnnList(..), AnnMaybe(..))
import qualified Language.Haskell.Tools.AST as AST
 
trfDoStmt :: TransformName n r => Located (Stmt n (LHsExpr n)) -> Trf (Ann AST.Stmt r)
trfDoStmt = trfLoc trfDoStmt'

trfDoStmt' :: TransformName n r => Stmt n (Located (HsExpr n)) -> Trf (AST.Stmt' AST.Expr r)
trfDoStmt' = gTrfDoStmt' trfExpr'

trfCmdDoStmt' :: TransformName n r => Stmt n (Located (HsCmd n)) -> Trf (AST.CmdStmt r)
trfCmdDoStmt' (RecStmt { recS_stmts = stmts }) = AST.RecStmt <$> trfAnnList "," trfCmdDoStmt' stmts
trfCmdDoStmt' stmt = AST.NonRecStmt <$> annCont (gTrfDoStmt' trfCmd' stmt)

gTrfDoStmt' :: TransformName n r => (ge n -> Trf (ae r)) -> Stmt n (Located (ge n)) -> Trf (AST.Stmt' ae r)
gTrfDoStmt' et (BindStmt pat expr _ _) = AST.BindStmt <$> trfPattern pat <*> (trfLoc et) expr
gTrfDoStmt' et (BodyStmt expr _ _ _) = AST.ExprStmt <$> annCont (et (unLoc expr))
gTrfDoStmt' et (LetStmt binds) = AST.LetStmt <$> addToScope binds (trfLocalBinds binds)
gTrfDoStmt' et (LastStmt body _) = AST.ExprStmt <$> annCont (et (unLoc body))

trfListCompStmts :: TransformName n r => [Located (Stmt n (LHsExpr n))] -> Trf (AnnList AST.ListCompBody r)
trfListCompStmts [unLoc -> ParStmt blocks _ _, unLoc -> (LastStmt {})]
  = nonemptyAnnList
      <$> trfScopedSequence (\(ParStmtBlock stmts _ _) -> 
                                let ann = toNodeAnnot $ collectLocs $ getNormalStmts stmts
                                 in Ann ann . AST.ListCompBody . AnnList ann . concat 
                                      <$> trfScopedSequence trfListCompStmt stmts
                            ) blocks
trfListCompStmts others 
  = let ann = (collectLocs $ getNormalStmts others)
     in AnnList (toNodeAnnot ann) . (:[]) 
          <$> annLoc (pure ann)
                     (AST.ListCompBody . AnnList (toNodeAnnot ann) . concat <$> trfScopedSequence trfListCompStmt others) 

trfListCompStmt :: TransformName n r => Located (Stmt n (LHsExpr n)) -> Trf [Ann AST.CompStmt r]
trfListCompStmt (L l trst@(TransStmt { trS_stmts = stmts })) 
  = (++) <$> (concat <$> local (\s -> s { contRange = mkSrcSpan (srcSpanStart (contRange s)) (srcSpanEnd (getLoc (last stmts))) }) (trfScopedSequence trfListCompStmt stmts)) 
         <*> ((:[]) <$> extractActualStmt trst)
-- last statement is extracted
trfListCompStmt (unLoc -> LastStmt _ _) = pure []
trfListCompStmt other = (:[]) <$> copyAnnot AST.CompStmt (trfDoStmt other)
  
extractActualStmt :: TransformName n r => Stmt n (LHsExpr n) -> Trf (Ann AST.CompStmt r)
extractActualStmt = \case
  TransStmt { trS_form = ThenForm, trS_using = using, trS_by = by } 
    -> addAnnotation by using (AST.ThenStmt <$> trfExpr using <*> trfMaybe "," "" trfExpr by)
  TransStmt { trS_form = GroupForm, trS_using = using, trS_by = by } 
    -> addAnnotation by using (AST.GroupStmt <$> (makeJust <$> trfExpr using) <*> trfMaybe "," "" trfExpr by)
  where addAnnotation by using
          = annLoc (combineSrcSpans (getLoc using) . combineSrcSpans (maybe noSrcSpan getLoc by)
                      <$> tokenLocBack AnnThen)
  
getNormalStmts :: [Located (Stmt n (LHsExpr n))] -> [Located (Stmt n (LHsExpr n))]
getNormalStmts (L _ (LastStmt body _) : rest) = getNormalStmts rest
getNormalStmts (stmt : rest) = stmt : getNormalStmts rest 
getNormalStmts [] = []
 
getLastStmt :: [Located (Stmt n (LHsExpr n))] -> Located (HsExpr n)
getLastStmt (L _ (LastStmt body _) : rest) = body
getLastStmt (_ : rest) = getLastStmt rest
  