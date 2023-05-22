import Logic.Predicate.FirstOrder.Principia.Principia
import Logic.Predicate.FirstOrder.Principia.RewriteFormula

open Qq Lean Elab Meta Tactic Term

namespace FirstOrder

namespace Principia
open SubFormula
variable {L : Language.{u}} [∀ k, DecidableEq (L.func k)] [∀ k, DecidableEq (L.rel k)] [L.Eq]
variable {T : Theory L} [EqTheory T]
variable {Δ : List (SyntacticFormula L)}

def castOfEq {Δ p p'} (hp : p = p') (b : Δ ⟹[T] p') : Δ ⟹[T] p :=
  b.cast hp.symm

def generalizeOfEq {Δ Δ' p p'}
  (hΔ : Δ.map shift = Δ') (hp : free p = p') (b : Δ' ⟹[T] p') : Δ ⟹[T] ∀' p :=
  generalize (b.cast' hΔ.symm hp.symm)

def generalizeBAllOfEq {Δ Δ' p p' q q'}
  (hΔ : Δ.map shift = Δ') (hp : free p = p') (hq : free q = q') (b : Δ' ⟹[T] p' ⟶ q') : Δ ⟹[T] ∀[p] q :=
  generalize (b.cast' hΔ.symm (by simp[←hp, ←hq]))

def specializeOfEq {t p p' q}
  (hp : ⟦↦ t⟧ p = p') (b : Δ ⟹[T] ∀' p) (d : (p' :: Δ) ⟹[T] q) : Δ ⟹[T] q :=
  ((b.specialize t).cast hp).trans d

def specializes : {k : ℕ} → (v : Fin k → SyntacticTerm L) → {p : SyntacticSubFormula L k} →
    (Δ ⟹[T] univClosure p) → (Δ ⟹[T] ⟦→ v⟧ p)
  | 0,     _, p, d => d.cast (by simp)
  | k + 1, v, p, d =>
    have : Δ ⟹[T] ∀' ⟦→ #0 :> SubTerm.bShift ∘ Matrix.vecTail v⟧ p := specializes (Matrix.vecTail v) d
    (specialize (Matrix.vecHead v) this).cast (by
      simp[substs_substs, Function.comp, Matrix.comp_vecCons']; congr;
      funext x; cases x using Fin.cases<;> simp[Matrix.vecTail, Matrix.vecHead]
      simp[SubTerm.substs, SubTerm.bShift, SubTerm.map, SubTerm.bind_bind])

def specializesOfEq {k v} {p : SyntacticSubFormula L k} {p' p'' q}
  (hp : ⟦→ v⟧ p = p') (hp' : univClosure p = p'') (b : Δ ⟹[T] p'') (d : (p' :: Δ) ⟹[T] q) : Δ ⟹[T] q :=
  (((b.cast hp'.symm).specializes v).cast hp).trans d

def exCasesOfEq {Δ Δ' p p' q q'}
  (hΔ : Δ.map shift = Δ') (hp : free p = p') (hq : shift q = q')
  (b₀ : Δ ⟹[T] ∃' p) (b₁ : (p' :: Δ') ⟹[T] q') : Δ ⟹[T] q :=
  b₀.exCases (b₁.cast' (by rw[hΔ, hp]) hq.symm)

def rewriteEqOfEq {t₁ t₂ p p₁ p₂} (h₁ : p₁ = ⟦↦ t₁⟧ p) (h₂ : ⟦↦ t₂⟧ p = p₂)
  (b : Δ ⟹[T] “ᵀ!t₁ = ᵀ!t₂”) (b' : Δ ⟹[T] p₂) : Δ ⟹[T] p₁ :=
  by simpa[h₁] using rewriteEq b (by simpa[←h₂] using b')

def useInstanceOfEq (t) {Δ p p'} (h : ⟦↦ t⟧ p = p')
  (b : Δ ⟹[T] p') : Δ ⟹[T] ∃' p :=
  useInstance t (b.cast h.symm)

def useInstanceBExOfEq (t) {Δ p p' q q'} (hp : ⟦↦ t⟧ p = p') (hq : ⟦↦ t⟧ q = q')
  (b : Δ ⟹[T] p' ⋏ q') : Δ ⟹[T] ∃[p] q :=
  useInstance t (b.cast (by simp[←hp, ←hq]))

def weakening {Δ Γ p} (h : Δ ⊆ Γ) (b : Δ ⟹[T] p) : Γ ⟹[T] p :=
  b.weakening' (List.cons_subset_cons _ h)

def transList {q} : (Γ : List (SyntacticFormula L)) → (∀ p ∈ Γ, Δ ⟹[T] p) → (Γ ⟹[T] q) → (Δ ⟹[T] q)
  | [],     _,  b₁ => b₁.weakening (by simp)
  | p :: Γ, b₀, b₁ => (transList Γ (fun r hr => b₀ r (by simp[hr])) b₁.intro).modusPonens (b₀ p (by simp))

protected def shift {p} (b : Δ ⟹[T] p) : (Δ.map shift) ⟹[T] shift p :=
  b.rewrite _

def apply  (b₁ : Δ ⟹[T] (q₁ ⟶ q₂)) (b₂ : Δ ⟹[T] q₁) (b₃ : (q₂ :: Δ) ⟹[T] p) : Δ ⟹[T] p :=
  (b₁.modusPonens b₂).trans b₃

def absurd {p} (b : (p :: Δ) ⟹[T] ⊥) : Δ ⟹[T] ~p :=
  (contradiction (~p) trivial b).weakening' (by simp)

def splitIff {p q} (b₁ : Δ ⟹[T] p ⟶ q) (b₂ : Δ ⟹[T] q ⟶ p) : Δ ⟹[T] p ⟷ q :=
  split b₁ b₂

def modusPonensOfIffLeft {p q} (b₀ : Δ ⟹[T] p ⟷ q) (b₁ : Δ ⟹[T] p) : Δ ⟹[T] q :=
  b₀.andLeft.modusPonens b₁

def modusPonensOfIffRight {p q} (b₀ : Δ ⟹[T] p ⟷ q) (b₁ : Δ ⟹[T] q) : Δ ⟹[T] p :=
  b₀.andRight.modusPonens b₁

def iffRefl (p) : Δ ⟹[T] p ⟷ p := split (intro $ assumption $ by simp) (intro $ assumption $ by simp) 

def iffReflOfEq {p q} (h : p = q) : Δ ⟹[T] p ⟷ q := by rw [h]; exact iffRefl q

def iffSymm {p q} (b : Δ ⟹[T] p ⟷ q) : Δ ⟹[T] q ⟷ p :=
  b.andRight.split b.andLeft

def iffTrans {p q r} (b₁ : Δ ⟹[T] p ⟷ q) (b₂ : Δ ⟹[T] q ⟷ r) : Δ ⟹[T] p ⟷ r :=
  split
    (intro $ modusPonens (b₂.andLeft.weakening (by simp)) $
      modusPonens (b₁.andLeft.weakening (by simp)) $ assumption (by simp))
    (intro $ modusPonens (b₁.andRight.weakening (by simp)) $
      modusPonens (b₂.andRight.weakening (by simp)) $ assumption (by simp))

def iffAnd {p₁ p₂ q₁ q₂} (b₁ : Δ ⟹[T] p₁ ⟷ q₁) (b₂ : Δ ⟹[T] p₂ ⟷ q₂) : Δ ⟹[T] p₁ ⋏ p₂ ⟷ q₁ ⋏ q₂ :=
  splitIff
    (intro $ split
        ((b₁.andLeft.weakening (List.subset_cons_of_subset _ $ by simp[List.subset_cons])).modusPonens $ andLeft (q := p₂) (assumption $ by simp))
        ((b₂.andLeft.weakening (List.subset_cons_of_subset _ $ by simp[List.subset_cons])).modusPonens $ andRight (p := p₁) (assumption $ by simp)))
    (intro $ split
        ((b₁.andRight.weakening (List.subset_cons_of_subset _ $ by simp[List.subset_cons])).modusPonens $ andLeft (q := q₂) (assumption $ by simp))
        ((b₂.andRight.weakening (List.subset_cons_of_subset _ $ by simp[List.subset_cons])).modusPonens $ andRight (p := q₁) (assumption $ by simp)))

def iffOr {p₁ p₂ q₁ q₂} (b₁ : Δ ⟹[T] p₁ ⟷ q₁) (b₂ : Δ ⟹[T] p₂ ⟷ q₂) : Δ ⟹[T] p₁ ⋎ p₂ ⟷ q₁ ⋎ q₂ :=
  splitIff
    (intro $ cases (p := p₁) (q := p₂) (assumption $ by simp)
      (orLeft $ (b₁.andLeft.weakening (List.subset_cons_of_subset _ $ by simp[List.subset_cons])).modusPonens $ assumption $ by simp)
      (orRight $ (b₂.andLeft.weakening (List.subset_cons_of_subset _ $ by simp[List.subset_cons])).modusPonens $ assumption $ by simp))
    (intro $ cases (p := q₁) (q := q₂) (assumption $ by simp)
      (orLeft $ (b₁.andRight.weakening (List.subset_cons_of_subset _ $ by simp[List.subset_cons])).modusPonens $ assumption $ by simp)
      (orRight $ (b₂.andRight.weakening (List.subset_cons_of_subset _ $ by simp[List.subset_cons])).modusPonens $ assumption $ by simp))

def iffNeg {p q} (b : Δ ⟹[T] p ⟷ q) : Δ ⟹[T] ~p ⟷ ~q :=
  splitIff
    (intro $ absurd $ contradiction (p := p) ⊥
      ((b.andRight.weakening (List.subset_cons_of_subset _ $ by simp)).modusPonens $ assumption $ by simp)
      (assumption $ by simp))
    (intro $ absurd $ contradiction (p := q) ⊥
      ((b.andLeft.weakening (List.subset_cons_of_subset _ $ by simp)).modusPonens $ assumption $ by simp)
      (assumption $ by simp))

def iffAll {p q} (b : Δ.map shift ⟹[T] free p ⟷ free q) : Δ ⟹[T] ∀' p ⟷ ∀' q :=
  splitIff
    (intro $ generalize $ (b.andLeft.weakening $ by simp).modusPonens $
      (specialize &0 (p := shift p) $ assumption $ by simp).cast (by simp))
    (intro $ generalize $ (b.andRight.weakening $ by simp).modusPonens $
      (specialize &0 (p := shift q) $ assumption $ by simp).cast (by simp))

def iffEx {p q} (b : Δ.map shift ⟹[T] free p ⟷ free q) : Δ ⟹[T] ∃' p ⟷ ∃' q :=
  splitIff
    (intro $ exCases (p := p) (assumption $ by simp) $ (useInstance &0 (p := shift q) $
      ((b.andLeft.weakening (List.subset_cons_of_subset _ $ by simp)).modusPonens $ assumption $ by simp).cast (by simp)).cast (by simp))
    (intro $ exCases (p := q) (assumption $ by simp) $ (useInstance &0 (p := shift p) $
      ((b.andRight.weakening (List.subset_cons_of_subset _ $ by simp)).modusPonens $ assumption $ by simp).cast (by simp)).cast (by simp))

def iffOfIffFormula {p₀ q₀} :
    {p q : SyntacticFormula L} → IffFormula p₀ q₀ p q → {Δ : List (SyntacticFormula L)} → (Δ ⟹[T] p₀ ⟷ q₀) → (Δ ⟹[T] p ⟷ q)
  | _, _, IffFormula.intro,         _, b => b
  | _, _, IffFormula.reflexivity p, Δ, _ => iffRefl _
  | _, _, IffFormula.and h₁ h₂,     Δ, b => iffAnd (iffOfIffFormula h₁ b) (iffOfIffFormula h₂ b)
  | _, _, IffFormula.or h₁ h₂,      Δ, b => iffOr (iffOfIffFormula h₁ b) (iffOfIffFormula h₂ b)
  | _, _, IffFormula.all h,         Δ, b => (iffOfIffFormula h (b.shift.cast $ by simp)).iffAll
  | _, _, IffFormula.ex h,          Δ, b => (iffOfIffFormula h (b.shift.cast $ by simp)).iffEx
  | _, _, IffFormula.neg h,         Δ, b => (iffOfIffFormula h b).iffNeg

def rephraseOfIffFormula {p₀ q₀ p q} (h : IffFormula p₀ q₀ p q) (b₀ : Δ ⟹[T] p₀ ⟷ q₀) (b₁ : Δ ⟹[T] q) : Δ ⟹[T] p :=
  (iffOfIffFormula h b₀).andRight.modusPonens b₁

def reflexivityOfEq {t₁ t₂ : SyntacticTerm L} (h : t₁ = t₂) :
    Δ ⟹[T] “ᵀ!t₁ = ᵀ!t₂” := by rw[h]; exact eqRefl _

end Principia

namespace Meta

namespace PrincipiaQ
open SubFormula
variable (L : Q(Language.{u}))
variable (dfunc : Q(∀ k, DecidableEq (($L).func k))) (drel : Q(∀ k, DecidableEq (($L).rel k))) (lEq : Q(Language.Eq $L)) 
variable (T : Q(Theory $L)) (eqTh : Q(EqTheory $T))
variable (Δ Δ' Γ : Q(List (SyntacticFormula $L)))

def castOfEqQ (p p' : Q(SyntacticFormula $L)) (hp : Q($p = $p')) (b : Q($Δ ⟹[$T] $p')) : Q($Δ ⟹[$T] $p) :=
  q(Principia.castOfEq $hp $b)

def assumptionQ (Γ : Q(List (SyntacticFormula $L))) (p : Q(SyntacticFormula $L)) (h : Q($p ∈ $Γ)) :
    Q($Γ ⟹[$T] $p) :=
  q(Principia.assumption $h)

def assumptionSymmQ (Γ : Q(List (SyntacticFormula $L))) (t₁ t₂ : Q(SyntacticTerm $L)) (h : Q(“ᵀ!$t₁ = ᵀ!$t₂” ∈ $Γ)) :
    Q($Γ ⟹[$T] “ᵀ!$t₂ = ᵀ!$t₁”) :=
  q(Principia.eqSymm $ Principia.assumption (p := “ᵀ!$t₁ = ᵀ!$t₂”) $h)

def assumptionIffSymmQ (Γ : Q(List (SyntacticFormula $L))) (p₁ p₂ : Q(SyntacticFormula $L)) (h : Q(($p₁ ⟷ $p₂) ∈ $Γ)) :
    Q($Γ ⟹[$T] $p₂ ⟷ $p₁) :=
  q(Principia.iffSymm $ Principia.assumption $h)

def generalizeOfEqQ (p : Q(SyntacticSubFormula $L 1)) (p' : Q(SyntacticFormula $L))
  (hΔ : Q(($Δ).map shift = $Δ')) (hp : Q(free $p = $p')) (b : Q($Δ' ⟹[$T] $p')) : Q($Δ ⟹[$T] ∀' $p) :=
  q(Principia.generalizeOfEq $hΔ $hp $b)

def generalizeBAllOfEqQ (p q : Q(SyntacticSubFormula $L 1)) (p' q' : Q(SyntacticFormula $L))
  (hΔ : Q(($Δ).map shift = $Δ')) (hp : Q(free $p = $p')) (hq : Q(free $q = $q')) (b : Q($Δ' ⟹[$T] $p' ⟶ $q')) : Q($Δ ⟹[$T] ∀[$p] $q) :=
  q(Principia.generalizeBAllOfEq $hΔ $hp $hq $b)

def specializeOfEqQ (t : Q(SyntacticTerm $L)) (p : Q(SyntacticSubFormula $L 1)) (p' q : Q(SyntacticFormula $L))
  (hp : Q(⟦↦ $t⟧ $p = $p')) (b : Q($Δ ⟹[$T] ∀' $p)) (d : Q(($p' :: $Δ) ⟹[$T] $q)) : Q($Δ ⟹[$T] $q) :=
  q(Principia.specializeOfEq $hp $b $d)

def specializesOfEqQ {k : Q(ℕ)} (v : Q(Fin $k → SyntacticTerm $L)) (p : Q(SyntacticSubFormula $L $k)) (p' p'' q : Q(SyntacticFormula $L))
  (hp : Q(⟦→ $v⟧ $p = $p')) (hp' : Q(univClosure $p = $p'')) (b : Q($Δ ⟹[$T] $p'')) (d : Q(($p' :: $Δ) ⟹[$T] $q)) : Q($Δ ⟹[$T] $q) :=
  q(Principia.specializesOfEq $hp $hp' $b $d)

def useInstanceOfEqQ (t : Q(SyntacticTerm $L)) (p : Q(SyntacticSubFormula $L 1)) (p' : Q(SyntacticFormula $L))
  (h : Q(⟦↦ $t⟧ $p = $p')) (b : Q($Δ ⟹[$T] $p')) : Q($Δ ⟹[$T] ∃' $p) :=
  q(Principia.useInstanceOfEq $t $h $b)

def useInstanceBExOfEqQ (t : Q(SyntacticTerm $L)) (p q : Q(SyntacticSubFormula $L 1)) (p' q' : Q(SyntacticFormula $L))
  (hp : Q(⟦↦ $t⟧ $p = $p')) (hq : Q(⟦↦ $t⟧ $q = $q')) (b : Q($Δ ⟹[$T] $p' ⋏ $q')) : Q($Δ ⟹[$T] ∃[$p] $q) :=
  q(Principia.useInstanceBExOfEq $t $hp $hq $b)

def rewriteEqOfEqQ (t₁ t₂ : Q(SyntacticTerm $L)) (p : Q(SyntacticSubFormula $L 1)) (p₁ p₂ : Q(SyntacticFormula $L))
  (h₁ : Q($p₁ = ⟦↦ $t₁⟧ $p)) (h₂ : Q(⟦↦ $t₂⟧ $p = $p₂))
  (b : Q($Δ ⟹[$T] “ᵀ!$t₁ = ᵀ!$t₂”)) (b' : Q($Δ ⟹[$T] $p₂)) : Q($Δ ⟹[$T] $p₁) :=
  q(Principia.rewriteEqOfEq $h₁ $h₂ $b $b')

def exCasesOfEqQ
  (p : Q(SyntacticSubFormula $L 1)) (p' : Q(SyntacticFormula $L))
  (q q' : Q(SyntacticFormula $L))
  (hΔ : Q(($Δ).map shift = $Δ')) (hp : Q(free $p = $p')) (hq : Q(shift $q = $q'))
  (b₀ : Q($Δ ⟹[$T] ∃' $p)) (b₁ : Q(($p' :: $Δ') ⟹[$T] $q')) : Q($Δ ⟹[$T] $q) :=
  q(Principia.exCasesOfEq $hΔ $hp $hq $b₀ $b₁)

def reflexivityOfEqQ (t₁ t₂ : Q(SyntacticTerm $L)) (h : Q($t₁ = $t₂)) :
    Q($Δ ⟹[$T] SubFormula.rel Language.Eq.eq ![$t₁, $t₂]) := q(Principia.reflexivityOfEq $h)

def iffReflOfEqQ (p₁ p₂ : Q(SyntacticFormula $L)) (h : Q($p₁ = $p₂)) :
    Q($Δ ⟹[$T] $p₁ ⟷ $p₂) := q(Principia.iffReflOfEq $h)

variable {m : Type → Type} [inst : Monad m]

def transListMQ {C : Type _} (q : Q(SyntacticFormula $L)) : (Γ : List (Q(SyntacticFormula $L) × C)) →
    (∀ p ∈ Γ, m Q($Δ ⟹[$T] $(p.1))) → Q($(Qq.toQList (u := u) (Γ.map Prod.fst)) ⟹[$T] $q) → m Q($Δ ⟹[$T] $q)
  | [],     _,  b₁ => return q(($b₁).weakening (by simp))
  | p :: Γ, b₀, b₁ => do
    have : Q($(Qq.toQList (u := u) (Γ.map Prod.fst)) ⟹[$T] $(p.1) ⟶ $q) := q(Principia.intro ($b₁))
    let ih : Q($Δ ⟹[$T] $(p.1) ⟶ $q) ← transListMQ q($(p.1) ⟶ $q) Γ (fun r hr => b₀ r (by simp[hr])) this
    let e : Q($Δ ⟹[$T] $(p.1)) ← b₀ p (by simp)
    return q(Principia.modusPonens $ih $e)

def transListMQ' {C : Type _} (Γ : List (Q(SyntacticFormula $L) × C)) (q r : Q(SyntacticFormula $L))
  (b₀ : ∀ p ∈ Γ, m Q($Δ ⟹[$T] $(p.1))) (b₁ : Q($(Qq.toQList (u := u) (Γ.map Prod.fst)) ⟹[$T] $q)) (b₂ : Q(($q :: $Δ) ⟹[$T] $r)) :
    m Q($Δ ⟹[$T] $r) := do
  let d ← transListMQ L dfunc drel lEq T Δ q Γ b₀ b₁
  return q(Principia.trans $d $b₂)

def transListQ {q : Q(SyntacticFormula $L)} : (Γ : List Q(SyntacticFormula $L)) →
    (∀ p ∈ Γ, Q($Δ ⟹[$T] $p)) → Q($(Qq.toQList (u := u) Γ) ⟹[$T] $q) → Q($Δ ⟹[$T] $q)
  | [],     _,  b₁ => q(($b₁).weakening (by simp))
  | p :: Γ, b₀, b₁ =>
    have : Q($(Qq.toQList (u := u) Γ) ⟹[$T] $p ⟶ $q) := q(Principia.intro ($b₁))
    have ih : Q($Δ ⟹[$T] $p ⟶ $q) := transListQ Γ (fun r hr => b₀ r (by simp[hr])) this
    have e : Q($Δ ⟹[$T] $p) := b₀ p (by simp)
    q(Principia.modusPonens $ih $e)

def rephraseOfIffFormulaQ (p₀ q₀ p q : Q(SyntacticFormula $L)) (h : Q(Principia.IffFormula $p₀ $q₀ $p $q))
  (b : Q($Δ ⟹[$T] $p₀ ⟷ $q₀)) (d : Q($Δ ⟹[$T] $q)) : Q($Δ ⟹[$T] $p) :=
  q(Principia.rephraseOfIffFormula $h $b $d)

end PrincipiaQ

section Syntax
variable (L : Q(Language.{u})) (n : Q(ℕ))
open SubTerm

syntax termSeq := (subterm),*

syntax lineIndex := "::[" num "]"

def linnIndexToNat : Syntax → TermElabM ℕ
  | `(lineIndex| ::[ $n:num ]) => return n.getNat
  | _                          => throwUnsupportedSyntax

syntax indexFormula := (lineIndex <|> subformula)

def subTermSyntaxToExpr (n : Q(ℕ)) : Syntax → TermElabM Q(SyntacticSubTerm $L $n)
  | `(subterm| $s:subterm) => do
    Term.elabTerm (←`(ᵀ“$s”)) (return q(SyntacticSubTerm $L $n))

def subFormulaSyntaxToExpr (n : Q(ℕ)) : Syntax → TermElabM Q(SyntacticSubFormula $L $n)
  | `(subformula| $s:subformula) => do
    Term.elabTerm (←`(“$s”)) (return q(SyntacticSubFormula $L $n))

def termSyntaxToExpr (s : Syntax) : TermElabM Q(SyntacticTerm $L) :=
  subTermSyntaxToExpr L q(0) s

def formulaSyntaxToExpr (s : Syntax) : TermElabM Q(SyntacticFormula $L) :=
  subFormulaSyntaxToExpr L q(0) s

def indexFormulaToFormula (E : List Expr) : Syntax → TermElabM Q(SyntacticFormula $L)
  | `(indexFormula| ::[ $n:num ])     => do
    let some p := E.get? (n.getNat) | throwError m!"error in indexFormulaToFormula: out of bound {E}"
    return p
  | `(indexFormula| $p:subformula) =>
    formulaSyntaxToExpr L p
  | _                              => throwUnsupportedSyntax

def dequantifier : (n : ℕ) → Q(SyntacticFormula $L) → TermElabM Q(SyntacticSubFormula $L $n)
  | 0,     p => return p
  | n + 1, p => do
    let p' ← dequantifier n p
    match p' with
    | ~q(∀' $q) => return q
    | ~q(∃' $q) => return q
    | ~q($q)    => throwError "error[dequantifier]: invalid number of quantifier"

def indexFormulaToSubFormula (E : List Q(SyntacticFormula $L)) (n : ℕ) : Syntax → TermElabM Q(SyntacticSubFormula $L $n)
  | `(indexFormula| ::[ $i:num ])  => do
    let some p := E.reverse.get? (i.getNat - 1) | throwError m!"error in indexFormulaToFormula: out of bound {E}"
    dequantifier L n p
  | `(indexFormula| $p:subformula) =>
    subFormulaSyntaxToExpr L q($n) p
  | _                              => throwUnsupportedSyntax

end Syntax

inductive PrincipiaCode (L : Q(Language.{u})) : Type
  | assumption    : PrincipiaCode L
  | trans         : Syntax → PrincipiaCode L → PrincipiaCode L → PrincipiaCode L
  | transList     : List (Syntax × PrincipiaCode L) →
    Syntax → PrincipiaCode L → PrincipiaCode L → PrincipiaCode L
  | contradiction : Syntax → PrincipiaCode L → PrincipiaCode L → PrincipiaCode L
  | trivial       : PrincipiaCode L
  | explode       : PrincipiaCode L → PrincipiaCode L
  | intro         : PrincipiaCode L → PrincipiaCode L
  | modusPonens   : Syntax → PrincipiaCode L → PrincipiaCode L → PrincipiaCode L  
  | apply         : Syntax → Syntax → PrincipiaCode L → PrincipiaCode L → PrincipiaCode L → PrincipiaCode L  
  | split         : PrincipiaCode L → PrincipiaCode L → PrincipiaCode L
  | andLeft       : Syntax → PrincipiaCode L → PrincipiaCode L
  | andRight      : Syntax → PrincipiaCode L → PrincipiaCode L
  | orLeft        : PrincipiaCode L → PrincipiaCode L
  | orRight       : PrincipiaCode L → PrincipiaCode L
  | cases         : Syntax → Syntax → PrincipiaCode L → PrincipiaCode L → PrincipiaCode L → PrincipiaCode L
  | generalize    : PrincipiaCode L → PrincipiaCode L
  | specialize    : List Syntax → Syntax → PrincipiaCode L → PrincipiaCode L → PrincipiaCode L
  | useInstance   : Syntax → PrincipiaCode L → PrincipiaCode L
  | exCases       : Syntax → PrincipiaCode L → PrincipiaCode L → PrincipiaCode L
  | reflexivity   : PrincipiaCode L
  | symmetry      : PrincipiaCode L → PrincipiaCode L
  | eqTrans       : Syntax → PrincipiaCode L → PrincipiaCode L → PrincipiaCode L
  | rewriteEq     : Syntax → Syntax → PrincipiaCode L → PrincipiaCode L → PrincipiaCode L
  | rephrase      : Syntax → Syntax → PrincipiaCode L → PrincipiaCode L → PrincipiaCode L
  | fromM         : Syntax → PrincipiaCode L
  | simpM         : SubTerm.Meta.NumeralUnfoldOption → List SubFormula.Meta.UnfoldOption → PrincipiaCode L → PrincipiaCode L
  | showState     : PrincipiaCode L → PrincipiaCode L
  | tryProve      : PrincipiaCode L
  | missing       : PrincipiaCode L

namespace PrincipiaCode
variable (L : Q(Language.{u}))

def toStr : PrincipiaCode L → String
  | assumption            => "assumption"
  | trans _ c₁ c₂         => "have: {\n" ++ c₁.toStr ++ "\n}" ++ c₂.toStr
  | transList _ _ c₁ c₂   => "have: {\n" ++ c₁.toStr ++ "\n}" ++ c₂.toStr
  | contradiction _ c₁ c₂ => "contradiction: {\n" ++ c₁.toStr ++ "\n}\nand: {\n" ++ c₂.toStr ++ "\n}"    
  | trivial               => "trivial"
  | explode c             => "explode" ++ c.toStr
  | intro c               => "intro\n" ++ c.toStr
  | modusPonens _ c₁ c₂   => "have: {\n" ++ c₁.toStr ++ "\n}\nand: {\n" ++ c₂.toStr ++ "\n}"
  | apply _ _ c₁ c₂ c₃    => "apply: {\n" ++ c₁.toStr ++ "\n}\nand: {\n" ++ c₂.toStr ++ "\n}\n" ++ c₃.toStr
  | split c₁ c₂           => "∧ split: {\n" ++ c₁.toStr ++ "\n}\nand: {\n" ++ c₂.toStr ++ "\n}"
  | andLeft _ c           => "∧ left\n" ++ c.toStr
  | andRight _ c          => "∧ right\n" ++ c.toStr
  | orLeft c              => "∨ left\n" ++ c.toStr
  | orRight c             => "∨ right\n" ++ c.toStr
  | cases _ _ c₀ c₁ c₂    => "∨ split: {\n" ++ c₀.toStr ++ "\n}\nor left: {\n" ++ c₁.toStr ++ "\n}\nor right: {\n" ++ c₂.toStr ++ "\n}"
  | generalize c          => "generalize\n" ++ c.toStr
  | specialize _ _ c₁ c₂  => "specialize\n" ++ c₁.toStr ++ "\n" ++ c₂.toStr
  | useInstance _ c       => "use\n" ++ c.toStr
  | exCases _ c₀ c₁       => "∃ cases: {\n" ++ c₀.toStr ++ "\n}\n" ++ c₁.toStr
  | reflexivity           => "reflexivity"
  | symmetry c            => "symmetryetry" ++ c.toStr
  | eqTrans _ c₁ c₂       => "trans: {\n" ++ c₁.toStr ++ "\n}\n and: {\n" ++ c₂.toStr ++ "\n}"
  | rewriteEq _ _ c₁ c₂   => "rewrite: {\n" ++ c₁.toStr ++ "\n}\n" ++ c₂.toStr
  | rephrase _ _ c₁ c₂    => "rephrase: {\n" ++ c₁.toStr ++ "\n}\n" ++ c₂.toStr
  | fromM _               => "from"
  | simpM _ _ c           => c.toStr   
  | showState c           => c.toStr
  | tryProve              => "try"
  | missing               => "?"

instance : Repr (PrincipiaCode L) := ⟨fun b _ => b.toStr L⟩

instance : ToString (PrincipiaCode L) := ⟨toStr L⟩

variable (dfunc : Q(∀ k, DecidableEq (($L).func k))) (drel : Q(∀ k, DecidableEq (($L).rel k))) (lEq : Q(Language.Eq $L)) 
variable (T : Q(Theory $L)) (eqTh : Q(EqTheory $T))

def display (E : List Q(SyntacticFormula $L)) (e : Q(SyntacticFormula $L)) : MetaM Unit := do
  -- logInfo m!"Language: {L}\nTheory: {T}"
  let (_, m) := E.foldr (fun e (s, m) => (s + 1, m ++ m!"{s+1}:    {e}\n")) (0, m! "")
  logInfo (m ++ m!"⊢\n0:    {e}")

def runRefl (E : List Q(SyntacticFormula $L)) (i : Q(SyntacticFormula $L)) : TermElabM Q($(Qq.toQList (u := u) E) ⟹[$T] $i) := do
    match i with
    | ~q(SubFormula.rel Language.Eq.eq ![$i₁, $i₂]) =>
      let ⟨i₁', ie₁⟩ ← SubTerm.Meta.result (L := L) (n := q(0)) SubTerm.Meta.NumeralUnfoldOption.all i₁
      let ⟨i₂', ie₂⟩ ← SubTerm.Meta.result (L := L) (n := q(0)) SubTerm.Meta.NumeralUnfoldOption.all i₂
      if (← isDefEq i₁' i₂') then
        let eqn : Q($i₁' = $i₂') := (q(@rfl (SyntacticTerm $L) $i₁') : Expr)
        let eqn : Q($i₁ = $i₂) := q(Eq.trans $ie₁ $ Eq.trans $eqn $ Eq.symm $ie₂)
        return PrincipiaQ.reflexivityOfEqQ L dfunc drel lEq T (Qq.toQList (u := u) E) i₁ i₂ eqn
      else throwError "term should be equal: {i₁}, {i₂}"
    | ~q($p₁ ⟷ $p₂) =>
      let ⟨p₁', pe₁⟩ ← SubFormula.Meta.result (L := L) (n := q(0)) SubTerm.Meta.NumeralUnfoldOption.all SubFormula.Meta.unfoldAll p₁
      let ⟨p₂', pe₂⟩ ← SubFormula.Meta.result (L := L) (n := q(0)) SubTerm.Meta.NumeralUnfoldOption.all SubFormula.Meta.unfoldAll p₂
      if (← isDefEq p₁' p₂') then
        let eqn : Q($p₁' = $p₂') := (q(@rfl (SyntacticFormula $L) $p₁') : Expr)
        let eqn : Q($p₁ = $p₂) := q(Eq.trans $pe₁ $ Eq.trans $eqn $ Eq.symm $pe₂)
        return PrincipiaQ.iffReflOfEqQ L dfunc drel lEq T (Qq.toQList (u := u) E) p₁ p₂ eqn
      else throwError "term should be equal: {p₁}, {p₂}"
    | _ => throwError "incorrect structure: {i} should be _ = _ or _ ↔ _"

partial def run : (c : PrincipiaCode L) → (G : List Q(SyntacticFormula $L)) → (e : Q(SyntacticFormula $L)) →
    TermElabM Q($(Qq.toQList (u := u) G) ⟹[$T] $e)
  | assumption, E, e  => do
    let some eh ← Qq.memQList? (u := u) e E | do display L E e; throwError m!"failed to prove {e} ∈ {E}" --el eVerum
    return PrincipiaQ.assumptionQ L dfunc drel lEq T (Qq.toQList (u := u) E) e eh
  | trans s c₁ c₂, E, p => do
    let q ← indexFormulaToSubFormula L E 0 s
    let b ← c₁.run E q
    let d ← c₂.run (q :: E) p
    return q(Principia.trans $b $d)
  | transList S s c₁ c₂, E, r => do
    let q ← indexFormulaToSubFormula L E 0 s
    let H ← S.mapM (fun (t, c) => return (←indexFormulaToSubFormula L E 0 t, c))
    let b₁ ← c₁.run (H.map Prod.fst) q
    let b₂ ← c₂.run (q :: E) r
    PrincipiaQ.transListMQ' L dfunc drel lEq T (Qq.toQList (u := u) E) H q r (fun (p, c) _ => c.run E p) b₁ b₂
  | contradiction s c₁ c₂, E, p => do
    let q ← indexFormulaToSubFormula L E 0 s
    let b₁ ← c₁.run E q
    let b₂ ← c₂.run E q(~$q)
    return q(Principia.contradiction $p $b₁ $b₂)
  | trivial, _, p => do
    match p with
    | ~q(⊤) => return q(Principia.trivial)
    | _ => throwError "incorrect structure: {p} should be ⊤"
  | explode c, E, _ => do
    let b ← c.run E q(⊥)
    return q(Principia.explode $b)
  | intro c, E, p => do
    match p with
    | ~q($p₁ ⟶ $p₂) =>
      let b ← c.run (p₁ :: E) p₂
      return q(Principia.intro $b)
    | _ => throwError "incorrect structure: {p} should be _ → _"
  | modusPonens s c₁ c₂, E, p => do
    let q ← indexFormulaToSubFormula L E 0 s
    let b₁ ← c₁.run E q($q ⟶ $p)
    let b₂ ← c₂.run E q
    return q(Principia.modusPonens $b₁ $b₂)
  | apply s₁ s₂ c₁ c₂ c₃, E, p => do
    let q₁ ← indexFormulaToSubFormula L E 0 s₁
    let q₂ ← indexFormulaToSubFormula L E 0 s₂
    let b₁ ← c₁.run E q($q₁ ⟶ $q₂)
    let b₂ ← c₂.run E q₁
    let b₃ ← c₃.run (q₂ :: E) p
    return q(Principia.apply $b₁ $b₂ $b₃)
  | split c₁ c₂, E, p => do
    match p with
    | ~q($p₁ ⋏ $p₂) =>
      let b₁ ← c₁.run E p₁
      let b₂ ← c₂.run E p₂
      return q(Principia.split $b₁ $b₂)
    | ~q($p₁ ⟷ $p₂) =>
      let b₁ ← c₁.run E q($p₁ ⟶ $p₂)
      let b₂ ← c₂.run E q($p₂ ⟶ $p₁)
      return q(Principia.splitIff $b₁ $b₂)
    | _ => throwError "incorrect structure: {p} should be _ ⋏ _ or _ ⟷ _"
  | andLeft s c, E, p => do
    let q ← indexFormulaToSubFormula L E 0 s    
    let b ← c.run E q($p ⋏ $q)
    return q(Principia.andLeft $b)
  | andRight s c, E, p => do
    let q ← indexFormulaToSubFormula L E 0 s    
    let b ← c.run E q($q ⋏ $p)
    return q(Principia.andRight $b)
  | orLeft c, E, p => do
    match p with
    | ~q($p₁ ⋎ $p₂) =>
      let b ← c.run E p₁
      return q(Principia.orLeft $b)
    | _             => throwError "incorrect structure: {p} should be _ ⋎ _"
  | orRight c, E, p => do
    match p with
    | ~q($p₁ ⋎ $p₂) =>
      let b ← c.run E p₂
      return q(Principia.orRight $b)
    | _ => throwError "incorrect structure: {p} should be _ ⋎ _"
  | cases s₁ s₂ c₀ c₁ c₂, E, p => do
    let q₁ ← indexFormulaToSubFormula L E 0 s₁
    let q₂ ← indexFormulaToSubFormula L E 0 s₂
    let b₀ ← c₀.run E q($q₁ ⋎ $q₂)
    let b₁ ← c₁.run (q₁ :: E) p
    let b₂ ← c₂.run (q₂ :: E) p
    return q(Principia.cases $b₀ $b₁ $b₂)
  | generalize c, E, e => do
    match e with
    | ~q(∀' $e)    =>
      let ⟨fe, fee⟩ ← SubFormula.Meta.resultFree e
      let ⟨sE, sEe⟩ ← SubFormula.Meta.resultShift₀List E
      let b ← c.run sE fe
      return PrincipiaQ.generalizeOfEqQ L dfunc drel lEq T
        (Qq.toQList (u := u) E) (Qq.toQList (u := u) sE) e fe sEe fee b
    | ~q(∀[$p] $q) =>
      let ⟨p', pe⟩ ← SubFormula.Meta.resultFree p
      let ⟨q', qe⟩ ← SubFormula.Meta.resultFree q
      let ⟨sE, sEe⟩ ← SubFormula.Meta.resultShift₀List E
      let b ← c.run sE q($p' ⟶ $q')
      return PrincipiaQ.generalizeBAllOfEqQ L dfunc drel lEq T
        (Qq.toQList (u := u) E) (Qq.toQList (u := u) sE) p q p' q' sEe pe qe b
    | _            => throwError "incorrect structure: {e} should be ∀ _"
  | specialize ts s c₀ c₁, E, p => do
    let k : ℕ := ts.length
    let kExpr : Q(ℕ) := q($k)
    let q ← indexFormulaToSubFormula L E k s
    let tsexpr ← ts.mapM (termSyntaxToExpr L)
    let (v, _) : Expr × ℕ := tsexpr.foldr (α := Expr) (fun t (w, k) =>
        let t : Q(SyntacticTerm $L) := t
        let w : Q(Fin $k → SyntacticTerm $L) := w
        (q(@Matrix.vecCons (SyntacticTerm $L) $k $t $w), k + 1))
        (q(@Matrix.vecEmpty (SyntacticTerm $L)), 0)
    let ⟨q', hp⟩ ← SubFormula.Meta.resultSubsts (n := q(0)) (k := q($k)) v q
    let ⟨q'', hp'⟩ ← SubFormula.Meta.resultUnivClosure q
    let b ← c₀.run E q''
    let d ← c₁.run (q' :: E) p
    return PrincipiaQ.specializesOfEqQ L dfunc drel lEq T (Qq.toQList (u := u) E) (k := kExpr) v q q' q'' p hp hp' b d
  | useInstance s c, E, p => do
    let t ← termSyntaxToExpr L s
    match p with
    | ~q(∃' $p) =>
      let ⟨p', pe⟩ ← SubFormula.Meta.resultSubsts (L := L) (k := q(1)) (n := q(0)) q(![$t]) p
      let b ← c.run E p'
      return PrincipiaQ.useInstanceOfEqQ L dfunc drel lEq T (Qq.toQList (u := u) E) t p p' pe b
    | ~q(∃[$p] $q) =>
      let ⟨p', pe⟩ ← SubFormula.Meta.resultSubsts (L := L) (k := q(1)) (n := q(0)) q(![$t]) p
      let ⟨q', qe⟩ ← SubFormula.Meta.resultSubsts (L := L) (k := q(1)) (n := q(0)) q(![$t]) q
      let b ← c.run E q($p' ⋏ $q')
      return PrincipiaQ.useInstanceBExOfEqQ L dfunc drel lEq T (Qq.toQList (u := u) E) t p q p' p' pe qe b
    | _ => throwError "incorrect structure: {p} should be ∃ _"
  | exCases s c₀ c₁, E, p => do
    let q ← indexFormulaToSubFormula L E 1 s
    let ⟨fe, fee⟩ ← SubFormula.Meta.resultFree (L := L) (n := q(0)) q
    let ⟨si, sie⟩ ← SubFormula.Meta.resultShift (L := L) (n := q(0)) p
    let ⟨sE, sEe⟩ ← SubFormula.Meta.resultShift₀List E
    let b₀ ← c₀.run E q(∃' $q)
    let b₁ ← c₁.run (fe :: sE) si
    return PrincipiaQ.exCasesOfEqQ L dfunc drel lEq T
      (Qq.toQList (u := u) E) (Qq.toQList (u := u) sE) q fe p si sEe fee sie b₀ b₁
  | reflexivity, E, i => runRefl L dfunc drel lEq T E i
  | symmetry c, E, i => do
    match i with
    | ~q(SubFormula.rel Language.Eq.eq ![$i₁, $i₂]) =>
      let b ← c.run E q(“ᵀ!$i₂ = ᵀ!$i₁”)
      return q(Principia.eqSymm $b)
    | ~q($p ⟷ $q) =>
      let b ← c.run E q($q ⟷ $p)
      return q(Principia.iffSymm $b)
    | _ => throwError "incorrect structure: {i} should be _ = _ or _ ↔ _"
  | rewriteEq s₁ s₂ c₀ c₁, E, p => do
    let t₁ ← termSyntaxToExpr L s₁
    let t₂ ← termSyntaxToExpr L s₂
    let ⟨p', hp⟩ ← SubFormula.Meta.findFormula t₁ p
    let ⟨p'', hp'⟩ ← SubFormula.Meta.resultSubsts q(![$t₂]) p'
    let b₀ ← c₀.run E q(“ᵀ!$t₁ = ᵀ!$t₂”)
    let b₁ ← c₁.run E p''
    return PrincipiaQ.rewriteEqOfEqQ L dfunc drel lEq T
      (Qq.toQList (u := u) E) t₁ t₂ p' p p'' hp hp' b₀ b₁
  | rephrase s₀ t₀ c₀ c₁, E, p => do
    let p₀ ← indexFormulaToSubFormula L E 0 s₀
    let q₀ ← indexFormulaToSubFormula L E 0 t₀
    let ⟨q, h⟩ ← SubFormula.Meta.rephraseFormula p₀ q₀ p
    let b₀ ← c₀.run E q(“!$p₀ ↔ !$q₀”)
    let b₁ ← c₁.run E q
    return PrincipiaQ.rephraseOfIffFormulaQ L dfunc drel lEq T
      (Qq.toQList (u := u) E) p₀ q₀ p q h b₀ b₁
  | fromM s, E, e => do
    Term.elabTerm s (return q($(Qq.toQList (u := u) E) ⟹[$T] $e))
  | simpM np l c, E, p => do
    let ⟨p', hp⟩ ← SubFormula.Meta.result (u := u) (L := L) (n := q(0)) np (SubFormula.Meta.unfoldOfList l) p
    logInfo m! "p': {p'}"
    let b ← c.run E p'
    return PrincipiaQ.castOfEqQ L dfunc drel lEq T (Qq.toQList (u := u) E) p p' hp b
  | showState c, E, e  => do
    display L E e
    let b ← c.run E e
    return q($b)
  | tryProve, E, e  => do
    let oh ← Qq.memQList? (u := u) e E
    match oh with
    | some eh => return PrincipiaQ.assumptionQ L dfunc drel lEq T (Qq.toQList (u := u) E) e eh
    | none    =>
      match e with
      | ~q(“ᵀ!$t₁ = ᵀ!$t₂”) =>
        let e' := q(“ᵀ!$t₂ = ᵀ!$t₁”)
        let oh' ← Qq.memQList? (u := u) e' E
        match oh' with
        | some eh' => return PrincipiaQ.assumptionSymmQ L dfunc drel lEq T (Qq.toQList (u := u) E) t₂ t₁ eh'
        | none     =>
          display L E e
          throwError m! "tryProve {e} failed"
      | ~q($p₁ ⟷ $p₂) =>
        let e' := q($p₂ ⟷ $p₁)
        let oh' ← Qq.memQList? (u := u) e' E
        match oh' with
        | some eh' => return PrincipiaQ.assumptionIffSymmQ L dfunc drel lEq T (Qq.toQList (u := u) E) p₂ p₁ eh'
        | none     =>
          display L E e
          throwError m! "tryProve {e} failed"
      | _     =>
        display L E e
        throwError m! "tryProve {e} failed"
  | _, E, e => do
    display L E e
    throwError m!"proof is missing" 

end PrincipiaCode

open Lean.Parser

declare_syntax_cat proofElem

@[inline] def proofElemParser (rbp : Nat := 0) : Parser :=
  categoryParser `proofElem rbp

def seqItem := leading_parser ppLine >> proofElemParser >> Lean.Parser.optional "; "

def seqIndent := leading_parser many1Indent seqItem

def seq := seqIndent

syntax metaBlock := "by " term

syntax proofBlock := "· " seq

syntax optProofBlock := ("@ " seq)?

syntax (name := notationAssumption) "assumption" : proofElem

syntax (name := notationHave) "have " indexFormula proofBlock : proofElem

syntax notationAndSeqUnit := "and" indexFormula optProofBlock

syntax (name := notationSinceThen)
  ("since" indexFormula optProofBlock notationAndSeqUnit*)? "then" indexFormula proofBlock : proofElem

syntax (name := notationContradiction) "contradiction " indexFormula optProofBlock optProofBlock : proofElem

syntax (name := notationTrivial) "trivial" : proofElem

syntax (name := notationIntro) "intro" : proofElem

syntax (name := notationModusPonens) "suffices" indexFormula optProofBlock : proofElem

syntax (name := notationSplit)"split" optProofBlock optProofBlock : proofElem

syntax (name := notationAndLeft) "andl" indexFormula optProofBlock : proofElem

syntax (name := notationAndRight) "andr" indexFormula optProofBlock : proofElem

syntax (name := notationOrLeft) "left" optProofBlock : proofElem

syntax (name := notationOrRight) "right" optProofBlock : proofElem

syntax (name := notationCases) "cases " indexFormula " or " indexFormula optProofBlock proofBlock proofBlock : proofElem

syntax (name := notationGeneralize) "generalize" : proofElem

syntax (name := notationSpecialize) "specialize" (subterm),* " of " indexFormula optProofBlock : proofElem

syntax (name := notationUse) "use " subterm : proofElem

syntax (name := notationExCases) "choose " indexFormula optProofBlock : proofElem

syntax (name := notationReflexivity) "rfl" : proofElem

syntax (name := notationSymmetry) "symmetry" : proofElem

syntax (name := notationRewriteEq) "rewrite" subterm " ↦ " subterm optProofBlock : proofElem

syntax (name := notationRephrase) "rephrase" indexFormula " ↦ " indexFormula optProofBlock : proofElem

syntax (name := notationFromM) "from " term : proofElem


syntax (name := notationShowState) "!" : proofElem

syntax (name := notationMissing) "?" : proofElem

declare_syntax_cat unfoldOpt

syntax "¬" : unfoldOpt
syntax "→" : unfoldOpt
syntax "↔" : unfoldOpt
syntax "∀b" : unfoldOpt
syntax "∃b" : unfoldOpt
syntax "+1" : unfoldOpt
syntax "+" : unfoldOpt

syntax unfoldOptSeq := "[" unfoldOpt,* "]"

syntax (name := notationSimpM) "simp" (unfoldOptSeq)? : proofElem

def unfoldOptToUnfoldOption : Syntax → TermElabM (SubTerm.Meta.NumeralUnfoldOption ⊕ SubFormula.Meta.UnfoldOption)
  | `(unfoldOpt| ¬)  => return Sum.inr SubFormula.Meta.UnfoldOption.neg
  | `(unfoldOpt| →) => return Sum.inr SubFormula.Meta.UnfoldOption.imply
  | `(unfoldOpt| ↔) => return Sum.inr SubFormula.Meta.UnfoldOption.iff
  | `(unfoldOpt| ∀b) => return Sum.inr SubFormula.Meta.UnfoldOption.ball
  | `(unfoldOpt| ∃b) => return Sum.inr SubFormula.Meta.UnfoldOption.bex
  | `(unfoldOpt| +1) => return Sum.inl SubTerm.Meta.NumeralUnfoldOption.unfoldSucc
  | `(unfoldOpt| +)  => return Sum.inl SubTerm.Meta.NumeralUnfoldOption.all
  | _                => throwUnsupportedSyntax

def unfoldOptSeqToListUnfoldOption : Syntax → TermElabM (SubTerm.Meta.NumeralUnfoldOption × List SubFormula.Meta.UnfoldOption)
  | `(unfoldOptSeq| [$ts,*]) => do
    let ts ← ts.getElems.mapM unfoldOptToUnfoldOption
    return ts.foldl (β := SubTerm.Meta.NumeralUnfoldOption × List SubFormula.Meta.UnfoldOption)
      (fun (np, l) => Sum.elim (fun np' => (np', l)) (fun up => (np, up :: l)) ) (SubTerm.Meta.NumeralUnfoldOption.none, [])
  | _                        => throwUnsupportedSyntax

private def getSeq (doStx : Syntax) : Syntax :=
  doStx[1]

private def getSeqElems (doSeq : Syntax) : List Syntax :=
  if doSeq.getKind == ``seqIndent then
    doSeq[0].getArgs.toList.map fun arg => arg[0]
  else
    []

def getSeqOfOptProofBlock (proofBlock : Syntax) : Syntax :=
  proofBlock[0][1]

def getSeqOfProofBlock (proofBlock : Syntax) : Syntax :=
  proofBlock[1]

partial def seqToCode (L : Q(Language.{u})) : List Syntax → TermElabM (PrincipiaCode L)
  | []                => return PrincipiaCode.tryProve
  | seqElem::seqElems => do
    match seqElem with
    | `(notationAssumption| assumption) => return PrincipiaCode.assumption
    | `(notationHave| have $p:indexFormula $s:proofBlock) =>
      let c₁ ← seqToCode L (getSeqElems <| getSeqOfProofBlock s)
      let c₂ ← seqToCode L seqElems
      return PrincipiaCode.trans p c₁ c₂
    | `(notationSinceThen| then $q $s:proofBlock) =>
      let sblock := getSeqOfProofBlock s
      let c ← seqToCode L (getSeqElems sblock)
      let cs ← seqToCode L seqElems
      return PrincipiaCode.transList [] q c cs
    | `(notationSinceThen| since $p $b:optProofBlock $andblock:notationAndSeqUnit* then $q $d:proofBlock) =>
      let dblock := getSeqOfProofBlock d
      let cthen ← seqToCode L (getSeqElems dblock)
      let cs ← seqToCode L seqElems
      let bblock := getSeqOfOptProofBlock b
      let csince := if bblock.isMissing then PrincipiaCode.tryProve else ← seqToCode L (getSeqElems bblock)
      let args ← andblock.mapM (fun s => do
        match s with
        | `(notationAndSeqUnit| and $r:indexFormula $z:optProofBlock) =>
          let zblock := getSeqOfOptProofBlock z
          let q := if zblock.isMissing then PrincipiaCode.tryProve else ← seqToCode L (getSeqElems zblock)
          return (r.raw, q)
        | _                                                         =>
          throwError f!"no match: {s}")
      let argList := (p.raw, csince) :: args.toList
      return PrincipiaCode.transList argList q cthen cs
    | `(notationContradiction| contradiction $p:indexFormula $b₁:optProofBlock $b₂:optProofBlock)
                                                        =>
      let bblock₁ := getSeqOfOptProofBlock b₁
      let bblock₂ := getSeqOfOptProofBlock b₂
      let c₁ := if bblock₁.isMissing then PrincipiaCode.tryProve else ← seqToCode L (getSeqElems bblock₁)
      let c₂ := if bblock₂.isMissing then PrincipiaCode.tryProve else ← seqToCode L (getSeqElems bblock₂)
      return PrincipiaCode.contradiction p c₁ c₂
    | `(notationTrivial| trivial)                       => return PrincipiaCode.trivial
    | `(notationIntro| intro)                           =>
      let c ← seqToCode L seqElems
      return PrincipiaCode.intro c
    | `(notationModusPonens| suffices $p:indexFormula $b:optProofBlock) =>
      let bblock := getSeqOfOptProofBlock b
      let c₀ := if bblock.isMissing then PrincipiaCode.tryProve else ← seqToCode L (getSeqElems bblock)
      let c₁ ← seqToCode L seqElems
      return PrincipiaCode.modusPonens p c₀ c₁
    | `(notationSplit| split $b₁:optProofBlock $b₂:optProofBlock) =>
      let bblock₁ := getSeqOfOptProofBlock b₁
      let bblock₂ := getSeqOfOptProofBlock b₂
      let c₁ := if bblock₁.isMissing then PrincipiaCode.tryProve else ← seqToCode L (getSeqElems bblock₁)
      let c₂ := if bblock₂.isMissing then PrincipiaCode.tryProve else ← seqToCode L (getSeqElems bblock₂)
      return PrincipiaCode.split c₁ c₂
    | `(notationAndLeft| andl $p:indexFormula $b:optProofBlock) =>
      let bblock := getSeqOfOptProofBlock b
      let c := if bblock.isMissing then PrincipiaCode.tryProve else ← seqToCode L (getSeqElems bblock)
      return PrincipiaCode.andLeft p c
    | `(notationAndRight| andr $p:indexFormula $b:optProofBlock) =>
      let bblock := getSeqOfOptProofBlock b
      let c := if bblock.isMissing then PrincipiaCode.tryProve else ← seqToCode L (getSeqElems bblock)
      return PrincipiaCode.andRight p c
    | `(notationOrLeft| left $b:optProofBlock) =>
      let bblock := getSeqOfOptProofBlock b
      let c := if bblock.isMissing then PrincipiaCode.tryProve else ← seqToCode L (getSeqElems bblock)
      return PrincipiaCode.orLeft c
    | `(notationOrRight| right $b:optProofBlock) =>
      let bblock := getSeqOfOptProofBlock b 
      let c := if bblock.isMissing then PrincipiaCode.tryProve else ← seqToCode L (getSeqElems bblock)
      return PrincipiaCode.orRight c
    | `(notationCases| cases $p:indexFormula or $q:indexFormula $b₀:optProofBlock $b₁:proofBlock $b₂:proofBlock) =>
      let bblock₀ := getSeqOfOptProofBlock b₀
      let bblock₁ := getSeqOfProofBlock b₁
      let bblock₂ := getSeqOfProofBlock b₂
      let c₀ := if bblock₀.isMissing then PrincipiaCode.tryProve else ← seqToCode L (getSeqElems bblock₀)
      let c₁ ← seqToCode L (getSeqElems bblock₁)
      let c₂ ← seqToCode L (getSeqElems bblock₂)
      return PrincipiaCode.cases p q c₀ c₁ c₂
    | `(notationGeneralize| generalize) =>
      let c ← seqToCode L seqElems
      return PrincipiaCode.generalize c
    | `(notationSpecialize| specialize $ts,* of $p:indexFormula $b:optProofBlock) =>
      let bblock := getSeqOfOptProofBlock b
      let c₀ := if bblock.isMissing then PrincipiaCode.tryProve else ← seqToCode L (getSeqElems bblock)
      let c ← seqToCode L seqElems
      return PrincipiaCode.specialize ts.getElems.toList p c₀ c
    | `(notationUse| use $t) =>
      let c ← seqToCode L seqElems
      return PrincipiaCode.useInstance t c
    | `(notationExCases| choose $p:indexFormula $b:optProofBlock) =>
      let bblock := getSeqOfOptProofBlock b
      let c₀ := if bblock.isMissing then PrincipiaCode.tryProve else ← seqToCode L (getSeqElems bblock)
      let c₁ ← seqToCode L seqElems
      return PrincipiaCode.exCases p c₀ c₁
    | `(notationReflexivity| rfl) =>
      return PrincipiaCode.reflexivity
    | `(notationSymmetry| symmetry) =>
      let c ← seqToCode L seqElems
      return PrincipiaCode.symmetry c
    | `(notationRewriteEq| rewrite $t₁:subterm ↦ $t₂:subterm $b:optProofBlock) =>
      let bblock := getSeqOfOptProofBlock b
      let c₀ := if bblock.isMissing then PrincipiaCode.tryProve else ← seqToCode L (getSeqElems bblock)
      let c₁ ← seqToCode L seqElems
      return PrincipiaCode.rewriteEq t₁ t₂ c₀ c₁
    | `(notationRephrase| rephrase $p₀:indexFormula ↦ $q₀:indexFormula $b:optProofBlock) =>
      let bblock := getSeqOfOptProofBlock b
      let c₀ := if bblock.isMissing then PrincipiaCode.tryProve else ← seqToCode L (getSeqElems bblock)
      let c₁ ← seqToCode L seqElems
      return PrincipiaCode.rephrase p₀ q₀ c₀ c₁
    | `(notationFromM| from $t:term) =>
      return PrincipiaCode.fromM t
    | `(notationSimpM| simp) =>
      let c ← seqToCode L seqElems
      return PrincipiaCode.simpM SubTerm.Meta.NumeralUnfoldOption.none [] c
    | `(notationSimpM| simp $ts:unfoldOptSeq) =>
      let c ← seqToCode L seqElems
      let (np, l) ← unfoldOptSeqToListUnfoldOption ts
      return PrincipiaCode.simpM np l c
    | `(notationShowState| !) =>
      let c ← seqToCode L seqElems
      return PrincipiaCode.showState c
    | `(notationMissing| ?) =>
      return PrincipiaCode.missing
    | _ => throwError f!"no match: {seqElem}"

syntax (name := elabproof) "proof." seq "□" : term
syntax (name := elabproofShort) "proofBy {" seq "}" : term

open Lean.Parser


@[term_elab elabproof]
def elabSeq : TermElab := fun stx typ? => do
  let seq := stx[1]
  let some typ := typ? | throwError "error: not a type"
  let some ⟨.succ u, typ'⟩ ← checkSortQ' typ | throwError "error: not a type"
  let ~q(@Principia $L $dfunc $drel $T $lEq $Γ $p) := typ' | throwError m!"error2: not a type: {typ'}"
  let c ← seqToCode L (getSeqElems seq)
  let E ← Qq.ofQList Γ
  let e ← PrincipiaCode.run L dfunc drel lEq T c E p
  return e

section
variable {L : Language.{u}} [∀ k, DecidableEq (L.func k)] [∀ k, DecidableEq (L.rel k)] [L.ORing]
variable {T : Theory L} [EqTheory T]

-- since ... and ... and ... ... then
example (h : [“0 < &0”, “&0 < 3”, “&0 ≠ 1”] ⟹[T] “&0 = 2”) :
    [“&0 ≠ 1”, “0 < &0 ∧ &9 = 1”, “&0 < 3”, “0 < &0”] ⟹[T] “&0 = 2” :=
  proof.
    since 0 < &0 and &0 < 3 and &0 ≠ 1 then &0 = 2
      · from h
  □

-- split
example : [“0 = &1”] ⟹[T] “&1 = 0” :=
  proof.
    !
  □

-- split
example : [“0 = &1”] ⟹[T] “⊤ ∧ (2 < 3 → 0 = &1)” :=
  proof.
    split
    @ trivial
    @ intro
  □

example : [] ⟹[T] “&0 = 1 ↔ &0 = 1 ∧ 1 = &0” :=
  proof.
    split
    @ intro
      split
      @ assumption
      @ symmetry
    @ intro
      andl 1 = &0
  □

-- contradiction
example : [“0 = 1”, “0 ≠ 1”] ⟹[T] “⊥” :=
  proof.
    contradiction 0 = 1
  □

-- suffices
example : [“&0 < 1 → &0 = 0”, “&0 < 1”] ⟹[T] “&0 = 0” :=
  proof.
    suffices &0 < 1
    assumption
  □

-- have
example : [“&0 < 1 → &0 = 0”, “&0 < 1”] ⟹[T] “&0 = 0 ∨ 0 < 2” :=
  proof.
    have &0 = 0
    · suffices &0 < 1
        assumption
    left
  □

-- cases ... or ... 
example : [“&0 = 0 ∨ ∃ &0 = #0 + 1”] ⟹[T] “∀ (&0 ≠ #0 + 1) → &0 = 0” :=
  proof.
    cases &0 = 0 or ∃ &0 = #0 + 1
    · intro
    · intro
      choose &0 = #0 + 1
      specialize &0 of &1 ≠ #0 + 1
      contradiction &1 = &0 + 1
  □

-- generalize
example : [“0 = &1”, “3 < &6 + &7”] ⟹[T] “∀ ∀ ∀ ((#0 = 0 ∨ #1 ≠ 0 ∨ #2 = 0) → ⊤)” :=
  proof.
    generalize 
    generalize 
    generalize
    intro 
    trivial
  □

-- specialize ..., ..., ... ... of ...
example : [“∀ ∀ #0 + #1 = #1 + #0”] ⟹[T] “1 + 2 = 2 + 1” :=
  proof.
    !
    specialize 1, 2 of #0 + #1 = #1 + #0
    !
  □

-- use ...
example : [] ⟹[T] “∃ ∃ ∃ #0 = #1 + #2” :=
  proof.
    use 1
    use 2
    use 3
    rfl
  □

-- choose ...
example : [“∃ #0 < &1”] ⟹[T] “⊤” :=
  proof.
    choose #0 < &1
    trivial
  □

-- rfl
example : [] ⟹[T] “0 = 1 + 1 ↔ 0 = 2” :=
  proof.
    rfl
  □

example : [] ⟹[T] “∀ (#0 = 1 + 1 → 0 < #0) ↔ ∀ (#0 ≠ 2 ∨ 0 < #0)” :=
  proof.
    rfl
  □

-- symmetry
example : [“1 = &0”] ⟹[T] “&0 = 1” :=
  proof.
    symmetry
  □

example : [“&0 < 1 ↔ &0 = 0”] ⟹[T] “&0 = 0 ↔ &0 < 1” :=
  proof.
    symmetry
  □

-- rewrite ... ↦ ...
example : [“&0 + 2 = 3”] ⟹[T] “∀ 3 * #0 = (&0 + 2) * #0” :=
  proof.
    rewrite &0 + 2 ↦ 3
    generalize rfl
  □

example :
  [ “∀ ∀ (#0 < #1 ↔ (∃ #0 + #1 + 1 = #2))”,
    “∀ #0 + 0 = #0”,
    “∀ (#0 = 0 ∨ (∃ #1 = #0 + 1))”] ⟹[T]
    “∀ (0 = #0 ∨ 0 < #0)” :=
  proof.
    generalize
    specialize &0 of ::[1]
    cases &0 = 0 or ∃ &0 = #0 + 1
    · left
      @ symmetry
    · have 0 < &0
      · choose ::[5]
        rewrite &1 ↦ &0 + 1
        rephrase 0 < &0 + 1 ↦ ∃ #0 + 0 + 1 = &0 + 1
        @ specialize 0, &0 + 1 of ::[3]
        use &0
        rewrite &0 + 0 ↦ &0
        @ specialize &0 of ::[2]
        rfl
      right
  □

end

end Meta

end FirstOrder