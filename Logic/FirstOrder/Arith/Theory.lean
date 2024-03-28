import Logic.FirstOrder.Arith.Hierarchy

namespace LO

namespace FirstOrder

variable {L : Language} [L.ORing] {ξ : Type*} [DecidableEq ξ]

namespace Arith

def succInd {ξ} (p : Semiformula L ξ 1) : Formula L ξ := “!p [0] → ∀ (!p [#0] → !p [#0 + 1]) → ∀ !p [#0]”

def orderInd {ξ} (p : Semiformula L ξ 1) : Formula L ξ := “∀ (∀[#0 < #1] !p [#0] → !p [#0]) → ∀ !p [#0]”

def leastNumber {ξ} (p : Semiformula L ξ 1) : Formula L ξ := “∃ !p [#0] → ∃ (!p [#0] ∧ ∀[#0 < #1] ¬!p [#0])”

def succIndᵤ (p : Semiformula L ξ 1) : Sentence L := ∀ᶠ* succInd p

variable (L)

namespace Theory

inductive peanoMinus : Theory ℒₒᵣ
  | addZero       : peanoMinus “∀ #0 + 0 = #0”
  | addAssoc      : peanoMinus “∀ ∀ ∀ (#2 + #1) + #0 = #2 + (#1 + #0)”
  | addComm       : peanoMinus “∀ ∀ #1 + #0 = #0 + #1”
  | addEqOfLt     : peanoMinus “∀ ∀ (#1 < #0 → ∃ #2 + #0 = #1)”
  | zeroLe        : peanoMinus “∀ (0 ≤ #0)”
  | zeroLtOne     : peanoMinus “0 < 1”
  | oneLeOfZeroLt : peanoMinus “∀ (0 < #0 → 1 ≤ #0)”
  | addLtAdd      : peanoMinus “∀ ∀ ∀ (#2 < #1 → #2 + #0 < #1 + #0)”
  | mulZero       : peanoMinus “∀ #0 * 0 = 0”
  | mulOne        : peanoMinus “∀ #0 * 1 = #0”
  | mulAssoc      : peanoMinus “∀ ∀ ∀ (#2 * #1) * #0 = #2 * (#1 * #0)”
  | mulComm       : peanoMinus “∀ ∀ #1 * #0 = #0 * #1”
  | mulLtMul      : peanoMinus “∀ ∀ ∀ (#2 < #1 ∧ 0 < #0 → #2 * #0 < #1 * #0)”
  | distr         : peanoMinus “∀ ∀ ∀ #2 * (#1 + #0) = #2 * #1 + #2 * #0”
  | ltIrrefl      : peanoMinus “∀ ¬#0 < #0”
  | ltTrans       : peanoMinus “∀ ∀ ∀ (#2 < #1 ∧ #1 < #0 → #2 < #0)”
  | ltTri         : peanoMinus “∀ ∀ (#1 < #0 ∨ #1 = #0 ∨ #0 < #1)”

notation "𝐏𝐀⁻" => peanoMinus

variable {L}

def indScheme (Γ : Semiformula L ℕ 1 → Prop) : Theory L :=
  { q | ∃ p : Semiformula L ℕ 1, Γ p ∧ q = ∀ᶠ* succInd p }

variable (L)

abbrev iOpen : Theory L := indScheme Semiformula.Open

notation "𝐈open" => iOpen ℒₒᵣ

abbrev iHierarchy (Γ : Polarity) (k : ℕ) : Theory L := indScheme (Arith.Hierarchy Γ k)

notation "𝐈𝐍𝐃" => iHierarchy ℒₒᵣ

abbrev iSigma (k : ℕ) : Theory L := indScheme (Arith.Hierarchy Σ k)

prefix:max "𝐈𝚺" => iSigma ℒₒᵣ

notation "𝐈𝚺₀" => iSigma ℒₒᵣ 0

abbrev iPi (k : ℕ) : Theory L := indScheme (Arith.Hierarchy Π k)

prefix:max "𝐈𝚷" => iPi ℒₒᵣ

notation "𝐈𝚷₀" => iPi ℒₒᵣ 0

abbrev peano : Theory L := indScheme Set.univ

notation "𝐏𝐀" => peano ℒₒᵣ

variable {L}

lemma coe_iHierarchy_subset_iHierarchy : (𝐈𝐍𝐃 Γ ν : Theory L) ⊆ iHierarchy L Γ ν := by
  simp [Theory.iHierarchy, Theory.indScheme]
  rintro _ p Hp rfl
  exact ⟨Semiformula.lMap (Language.oringEmb : ℒₒᵣ →ᵥ L) p, Hierarchy.oringEmb Hp,
    by simp [Formula.lMap_fvUnivClosure, succInd, Semiformula.lMap_substs]⟩

end Theory

end Arith

end FirstOrder
