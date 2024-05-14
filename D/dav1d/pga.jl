# Projective Geometric Algebra for General Relativity

Minkowski:

e^a ⋅ e^b = η^ab

Variables (one-forms):

tetrad:                      e^a
Ricci rotation coefficients: ω^ab

Derived quantities (two-forms):

torsion:   T^a  = d e^a  + ω^a_b ∧ e^b
curvature: R^ab = d ω^ab + ω^a_c ∧ ω^cb

4d spacetime: a, b, c, ... = t, x, y, z
5th new dimension: w
5d manifold: A, B, C, ... = w, t, x, y, z

e^w ⋅ e^w = 0
e^w ⋅ e^a = 0

("Poincaré")

P_μ^AB = [e_μ^a, ω_μ^ab]
R_μν^AB = [T_μν^a, R_μν^ab]

R^AB = d P^AB + P^A_C ∧ P^CB
     = [d e^a + ω^a_c ∧ e^c | d ω^ab + ω^a_c ∧ ω^cb]
     = [T^a | R^ab]

Action:

which of these?
- options: external or covariant derivative
- internal indices traced or with ϵ
- covariant derivative of `P` is actually covariant or not

(1): d P^AB ∧ * d P_AB = d ω^ab ∧ * d ω_ab
(2): D P^AB ∧ * D P_AB

(1) D ω^ab = d ω^ab + w^a_c ω^cb
(2) D ω^ab = d ω^ab + w^a_c ω^cb + w_c^b ω^ac
