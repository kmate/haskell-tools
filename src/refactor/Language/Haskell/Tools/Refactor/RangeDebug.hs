{-# LANGUAGE TypeOperators
           , DefaultSignatures
           , StandaloneDeriving
           , FlexibleContexts
           , FlexibleInstances
           , MultiParamTypeClasses
           , TypeFamilies
           #-}
module Language.Haskell.Tools.Refactor.RangeDebug where

import GHC.Generics
import Control.Reference
import SrcLoc
import Language.Haskell.Tools.AST
import Language.Haskell.Tools.AST.FromGHC
import Language.Haskell.Tools.AnnTrf.RangeToRangeTemplate
import Language.Haskell.Tools.AnnTrf.RangeTemplate
import Language.Haskell.Tools.AnnTrf.SourceTemplate

rangeDebug :: (a ~ NodeInfo sema SpanInfo, TreeDebug e a) => e a -> String
rangeDebug = treeDebug' (shortShowSpanInfo . (^. sourceInfo)) 0
      
shortShowSpanInfo :: SpanInfo -> String
shortShowSpanInfo (NodeSpan sp) = shortShowSpan sp
shortShowSpanInfo (OptionalPos bef aft loc) = "?" ++ show bef ++ " " ++ show aft ++ " " ++ shortShowLoc loc
shortShowSpanInfo (ListPos bef aft sep _ loc) = "*" ++ show bef ++ " " ++ show sep ++ " " ++ show aft ++ " " ++ shortShowLoc loc
      
shortShowSpan :: SrcSpan -> String
shortShowSpan (UnhelpfulSpan _) = "??-??" 
shortShowSpan sp@(RealSrcSpan _) 
  = shortShowLoc (srcSpanStart sp) ++ "-" ++ shortShowLoc (srcSpanEnd sp)
      
shortShowLoc :: SrcLoc -> String
shortShowLoc (UnhelpfulLoc _) = "??"
shortShowLoc (RealSrcLoc loc) = show (srcLocLine loc) ++ ":" ++ show (srcLocCol loc)
      
templateDebug :: TreeDebug e (NodeInfo sema RangeTemplate) => e (NodeInfo sema RangeTemplate) -> String
templateDebug = treeDebug' (shortShowRangeTemplate . (^. sourceInfo)) 0

shortShowRangeTemplate (RangeTemplate _ rngs) = "ˇ" ++ concatMap showRangeTemplateElem rngs ++ "ˇ"
  where showRangeTemplateElem (RangeElem sp) = "[" ++ shortShowSpan (RealSrcSpan sp) ++ "]"
        showRangeTemplateElem (RangeChildElem) = "."
        showRangeTemplateElem r = show r

sourceTemplateDebug :: TreeDebug e (NodeInfo sema SourceTemplate) => e (NodeInfo sema SourceTemplate) -> String
sourceTemplateDebug = treeDebug' (shortShowSourceTemplate . (^. sourceInfo)) 0

shortShowSourceTemplate temp = "ˇ" ++ (concatMap show $ temp ^. sourceTemplateElems) ++ "ˇ"
      
class TreeDebug e a where
  treeDebug' :: (a -> String) -> Int -> e a -> String
  default treeDebug' :: (GTreeDebug (Rep (e a)) a, Generic (e a)) => (a -> String) -> Int -> e a -> String
  treeDebug' f i = gTreeDebug f i . from

class GTreeDebug f a where 
  gTreeDebug :: (a -> String) -> Int -> f p -> String
  
instance GTreeDebug V1 a where
  gTreeDebug _ _ _ = error "GTreeDebug V1"
  
instance GTreeDebug U1 a where
  gTreeDebug _ _ U1 = ""  
  
instance (GTreeDebug f a, GTreeDebug g a) => GTreeDebug (f :+: g) a where
  gTreeDebug f i (L1 x) = gTreeDebug f i x
  gTreeDebug f i (R1 x) = gTreeDebug f i x
  
instance (GTreeDebug f a, GTreeDebug g a) => GTreeDebug (f :*: g) a where
  gTreeDebug f i (x :*: y) 
    = gTreeDebug f i x ++ gTreeDebug f i y

instance {-# OVERLAPPING #-} TreeDebug e a => GTreeDebug (K1 i (e a)) a where
  gTreeDebug f i (K1 x) = treeDebug' f i x
  
instance {-# OVERLAPPABLE #-} GTreeDebug (K1 i c) a where
  gTreeDebug f i (K1 x) = ""
        
instance GTreeDebug f a => GTreeDebug (M1 i t f) a where
  gTreeDebug f i (M1 x) = gTreeDebug f i x
