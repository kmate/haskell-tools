
{-# LANGUAGE TypeFamilies
           , KindSignatures
           , MultiParamTypeClasses
           , FlexibleInstances
           , UndecidableInstances
           , TypeOperators
           #-}

-- | Simple AST elements of Haskell
module Language.Haskell.Tools.AST.Base where
  
import Language.Haskell.Tools.AST.Ann

data AnnotationSemantic = AnnotationSemantic
data IdenticSemantic = IdenticSemantic

data IdSem
data ListSem
data MaybeSem
data a :> b
infixr 5 :>

type family PrimSemantic sem (elem :: * -> *) :: * -> *
type instance PrimSemantic IdSem    elem = Ann elem
type instance PrimSemantic ListSem  elem = AnnList elem
type instance PrimSemantic MaybeSem elem = AnnMaybe elem
type instance PrimSemantic (a :> b) elem = (PrimSemantic a (PrimSemantic b elem))

type family StSem wt sem (elem :: * -> * -> *) info
type instance StSem wt sem elem info = PrimSemantic sem (elem wt) info


type family NodeSemantic wt sem (elem :: * -> *) :: * -> *

type instance NodeSemantic IdenticSemantic IdSem    elem = elem
type instance NodeSemantic IdenticSemantic ListSem  elem = [elem]
type instance NodeSemantic IdenticSemantic MaybeSem elem = Maybe elem

type instance NodeSemantic AnnotationSemantic IdSem    elem = Ann      elem
type instance NodeSemantic AnnotationSemantic ListSem  elem = AnnList  elem
type instance NodeSemantic AnnotationSemantic MaybeSem elem = AnnMaybe elem

class StructuralSemantic sem (elem :: * -> * -> *) info where
    type IdType    elem sem info
    type ListType  elem sem info
    type MaybeType elem sem info
    type ListMaybeType elem sem info
    type MaybeListType elem sem info
    type ListListType elem sem info

instance StructuralSemantic AnnotationSemantic elem annot where
    type IdType    elem AnnotationSemantic annot = Ann      (elem AnnotationSemantic) annot
    type ListType  elem AnnotationSemantic annot = AnnList  (elem AnnotationSemantic) annot
    type MaybeType elem AnnotationSemantic annot = AnnMaybe (elem AnnotationSemantic) annot
    type ListMaybeType elem AnnotationSemantic annot = AnnList (AnnMaybe (elem AnnotationSemantic)) annot
    type MaybeListType elem AnnotationSemantic annot = AnnMaybe (AnnList (elem AnnotationSemantic)) annot
    type ListListType  elem AnnotationSemantic annot = AnnList (AnnList (elem AnnotationSemantic)) annot

instance StructuralSemantic IdenticSemantic elem info where
    type IdType    elem IdenticSemantic info = elem IdenticSemantic info
    type ListType  elem IdenticSemantic info = [elem IdenticSemantic info]
    type MaybeType elem IdenticSemantic info = Maybe (elem IdenticSemantic info)
    type ListMaybeType elem IdenticSemantic info = [Maybe (elem IdenticSemantic info)]
    type MaybeListType elem IdenticSemantic info = Maybe [elem IdenticSemantic info]
    type ListListType  elem IdenticSemantic info = [[elem IdenticSemantic info]]

data Box (typ :: (* -> * -> *) -> * -> * -> *) (elem :: * -> * -> *) sem a = Box { unBox :: typ elem sem a }

data BoxListType (elem :: * -> * -> *) sem a = BoxListType { unBoxListType :: ListType elem sem a }


-- | Possible qualified names. Contains wt also implicit names.
-- Linear implicit parameter: @%x@. Non-linear implicit parameter: @?x@.
data Name wt a = Name { qualifiers      :: ListType SimpleName wt a
                      , unqualifiedName :: IdType SimpleName wt a 
                      } 
                   
nameFromList :: AnnList (SimpleName AnnotationSemantic) a -> Name AnnotationSemantic a
nameFromList (AnnList xs) | not (null xs) 
  = Name (AnnList $ init xs) (last xs) 
nameFromList _ = error "nameFromList: empty list"
         
-- | Parts of wt a qualified name.         
data SimpleName wt a 
  = SimpleName { simpleNameStr :: String } 
               
-- | Program elements formatted wt as string literals (import packages, pragma texts)
data StringNode wt a
  = StringNode { stringNodeStr :: String }
                   
-- | The @data@ or the @newtype@ keyword to define ADTs.
data DataOrNewtypeKeyword wt a
  = DataKeyword
  | NewtypeKeyword
    
-- | Keywords @do@ or @mdo@ to start wt a do-block
data DoKind wt a
  = DoKeyword
  | MDoKeyword
  
-- | The @type@ keyword used to qualify that the type wt and not the constructor of the same name is referred
data TypeKeyword wt a = TypeKeyword
  
-- | Recognised overlaps for overlap pragmas. Can be wt applied to class declarations wt and class instance declarations.    
data OverlapPragma wt a
  = EnableOverlap     -- ^ @OVERLAP@ pragma
  | DisableOverlap    -- ^ @NO_OVERLAP@ pragma
  | Overlappable      -- ^ @OVERLAPPABLE@ pragma
  | Overlapping       -- ^ @OVERLAPPING@ pragma
  | Overlaps          -- ^ @OVERLAPS@ pragma
  | IncoherentOverlap -- ^ @INCOHERENT@ pragma
  
-- | Call conventions of foreign functions
data CallConv wt a
  = StdCall
  | CCall
  | CPlusPlus
  | DotNet
  | Jvm
  | Js
  | JavaScript
  | CApi
  
data ArrowAppl wt a
  = LeftAppl
  | RightAppl
  | LeftHighApp
  | RightHighApp
  
data Safety wt a
  = Safe
  | ThreadSafe
  | Unsafe
  | Interruptible

-- | Associativity of wt an operator.
data Assoc wt a
  = AssocNone  -- ^ non-associative operator (declared with @infix@)
  | AssocLeft  -- ^ left-associative operator (declared with @infixl@)
  | AssocRight -- ^ right-associative operator (declared with @infixr@)
  
-- | Numeric precedence of wt an operator
data Precedence wt a
  = Precedence { precedenceValue :: Int } 
     
-- | Controls the wt activation of wt a rewrite rule (@ [1] @)
data PhaseControl wt a
  = PhaseControl { phaseInvert :: MaybeType PhaseInvert wt a
                 , phaseNumber :: IdType PhaseNumber wt a
                 } 

data PhaseNumber wt a = PhaseNumber { phaseNum :: Integer }

-- | A tilde that marks the inversion of the phase number
data PhaseInvert wt a = PhaseInvert

