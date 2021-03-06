{-# LANGUAGE TemplateHaskell
           , DeriveDataTypeable
           #-}
-- | The range template is an intermediate annotation level, where the children nodes of the tree
-- had been cut from the parent nodes, but the annotations still contain ranges instead of text.
module Language.Haskell.Tools.AnnTrf.RangeTemplate where

import Data.Data
import Control.Reference
import SrcLoc

data RangeTemplateElem = RangeElem RealSrcSpan
                       | RangeChildElem
                       | RangeOptionalElem String String
                       | RangeListElem String String String Bool [RealSrcSpan]
                       deriving Data

getRangeElemSpan :: RangeTemplateElem -> Maybe RealSrcSpan
getRangeElemSpan (RangeElem sp) = Just sp
getRangeElemSpan _ = Nothing
                       
instance Show RangeTemplateElem where
  show (RangeElem sp) = show sp
  show RangeChildElem = "«.»"
  show (RangeOptionalElem bef aft) = "«?" ++ show bef ++ " " ++ show aft ++ "?»"
  show (RangeListElem bef aft sep _ _) = "«*" ++ show bef ++ " " ++ show sep ++ " " ++ show aft ++ "*»"
  
-- | The intermediate annotation with ranges and children cut out from parents.
data RangeTemplate = RangeTemplate { _rangeTemplateSpan :: RealSrcSpan
                                   , _rangeTemplateElems :: [RangeTemplateElem] 
                                   } deriving Data
                                   
makeReferences ''RangeTemplate      

instance Show RangeTemplate where
  show (RangeTemplate rng rngs) = show rngs
