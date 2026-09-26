# Deriving the uplink NOMA QUBO

This note develops the QUBO used in [`noma_detection.py`](../src/noma_detection.py) for BPSK, QPSK, 16-QAM, and 64-QAM. It uses the symbol encodings in Chapter 4 of the [EE599 thesis](EE599-thesis.pdf) and the expanded 16-QAM and 64-QAM coefficient listings in its Appendix A. The compact complex form below generates every diagonal and pairwise coefficient, including the entries expanded by real and imaginary channel components in the appendix.

## 1. Signal model and binary objective

For one received complex sample at the base station, let

$$
y=\sum_{k=1}^{K} H_k s_k+n, \qquad H_k=\sqrt{P_k}h_k.
$$

Here $h_k$ is the complex channel (including fading and path loss), $P_k$ is the power scale in watts, $s_k$ is a constellation symbol, and $n$ is complex noise. With known channels and equal noise variance across candidate symbol vectors, maximum-likelihood detection minimizes

$$
E(\mathbf{s})=\left|y-\sum_{k=1}^{K}H_ks_k\right|^2.
$$

Represent a symbol by binary variables $q_{kb}\in\{0,1\}$:

$$
s_k=c+\sum_{b=1}^{B}w_bq_{kb}, \qquad B=\log_2|\mathcal S|.
$$

The constant $c$ and complex weights $w_b$ depend on the modulation. Define $d=y-c\sum_k H_k$ and, for the flattened bit index $i=(k,b)$, $A_i=H_kw_b$. Then

$$
E(\mathbf q)=\left|d-\sum_i A_iq_i\right|^2.
$$

Multiplying this expression by its complex conjugate gives

$$
E(\mathbf q)=|d|^2-2\sum_i\Re(\overline d A_i)q_i
+\sum_i|A_i|^2q_i^2
+2\sum_{i<j}\Re(\overline {A_i}A_j)q_iq_j.
$$

Because $q_i^2=q_i$, the QUBO with **one stored coefficient per unordered pair** is

$$
E(\mathbf q)=E_0+\sum_i Q_{ii}q_i+\sum_{i<j}Q_{ij}q_iq_j,
$$

$$
E_0=|d|^2,\qquad
Q_{ii}=|A_i|^2-2\Re(\overline d A_i),\qquad
Q_{ij}=2\Re(\overline {A_i}A_j).
$$

$E_0$ does not change the minimizer, but it is retained when checking the QUBO energy against the original squared residual. The code uses zero-based user and bit indices; the thesis equations use one-based indices. These are the same variables in the same within-user order.

## 2. BPSK: one bit per user

For $q_k\in\{0,1\}$, choose $s_k=2q_k-1$. Thus $c=-1$, $w_1=2$, $d=y+\sum_k H_k$, and $A_k=2H_k$. Substitution yields

$$
Q_{kk}=4|H_k|^2-4\Re(\overline d H_k),\qquad
Q_{k\ell}=8\Re(\overline {H_k}H_\ell)\quad(k<\ell).
$$

With equal power $P_k=P$, substituting $H_k=\sqrt P h_k$ and expanding $d$ gives an equivalent diagonal form:

$$
Q_{kk}=-4\sqrt P\,\Re(\overline y h_k)
-4P\sum_{\ell\ne k}\Re(\overline {h_\ell}h_k).
$$

For complex numbers $u,v$, $\Re(\overline u v)=u_{\rm R}v_{\rm R}+u_{\rm I}v_{\rm I}$; applying this identity recovers the real/imaginary BPSK coefficients in the thesis.

## 3. QPSK: real and imaginary bits

The thesis uses the four points $(\pm1\pm j)/\sqrt2$. In real-bit, imaginary-bit order,

$$
s_k=\frac{(2q_{k,R}-1)+j(2q_{k,I}-1)}{\sqrt2}.
$$

Therefore $c=-(1+j)/\sqrt2$, $w_R=\sqrt2$, $w_I=j\sqrt2$, and $d=y+(1+j)\sum_kH_k/\sqrt2$. The two diagonal coefficients are

$$
Q_{kR,kR}=2|H_k|^2-2\sqrt2\,\Re(\overline d H_k),
$$

$$
Q_{kI,kI}=2|H_k|^2-2\sqrt2\,\Re(j\overline d H_k).
$$

The bits of *one* user have no pairwise coupling: $Q_{kR,kI}=2\Re(2j|H_k|^2)=0$. Across different users, the coefficients follow $2\Re(\overline{H_kw_b}H_\ell w_c)$. For example,

$$
Q_{kR,\ell R}=4\Re(\overline {H_k}H_\ell),\qquad
Q_{kR,\ell I}=4\Re(j\overline {H_k}H_\ell).
$$

The corresponding $I,R$ term has the opposite imaginary rotation. Keeping the complex product in the implementation avoids separate sign cases for every real/imaginary combination.

## 4. 16-QAM: two bits on each axis

Let $b=1/(3\sqrt2)$. The real and imaginary amplitudes are each selected from $\{-3b,-b,b,3b\}$ by two binary bits:

$$
s_k=b\left[(4q_{k,R1}+2q_{k,R2}-3)
+j(4q_{k,I1}+2q_{k,I2}-3)\right].
$$

Thus $c=-3b(1+j)$ and the ordered weights are $(4b,2b,4jb,2jb)$. There are $4K$ QUBO variables. Define $d=y+3b(1+j)\sum_kH_k$. Each diagonal comes from $Q_{kb,kb}=|H_k w_b|^2-2\Re(\overline d H_kw_b)$:

| Bit | Weight $w_b$ | Diagonal $Q_{kb,kb}$ |
| --- | --- | --- |
| $R1$ | $4b$ | $16b^2|H_k|^2-8b\Re(\overline d H_k)$ |
| $R2$ | $2b$ | $4b^2|H_k|^2-4b\Re(\overline d H_k)$ |
| $I1$ | $4jb$ | $16b^2|H_k|^2-8b\Re(j\overline d H_k)$ |
| $I2$ | $2jb$ | $4b^2|H_k|^2-4b\Re(j\overline d H_k)$ |

Within one user, $Q_{kR1,kR2}=Q_{kI1,kI2}=16b^2|H_k|^2=8|H_k|^2/9$. Any real-axis/imaginary-axis pair belonging to the same user has zero coupling because the product is purely imaginary. For bits on different users, insert their two weights into $Q_{ij}=2\Re(\overline{H_kw_b}H_\ell w_c)$. This one rule generates the longer real/imaginary coefficient table in Appendix A.

## 5. 64-QAM: three bits on each axis

Let $a=1/(7\sqrt2)$. Three bits choose an amplitude from $\{-7a,-5a,-3a,-a,a,3a,5a,7a\}$ on each axis:

$$
s_k=a\left[(8q_{k,R1}+4q_{k,R2}+2q_{k,R3}-7)
+j(8q_{k,I1}+4q_{k,I2}+2q_{k,I3}-7)\right].
$$

Here $c=-7a(1+j)$, the ordered weights are $(8a,4a,2a,8ja,4ja,2ja)$, and there are $6K$ variables. Put $d=y+7a(1+j)\sum_kH_k$. All six diagonal coefficients follow the same diagonal rule. For a real-axis weight $ta$, where $t\in\{8,4,2\}$,

$$
Q_{kR_t,kR_t}=t^2a^2|H_k|^2-2ta\Re(\overline d H_k).
$$

For the corresponding imaginary-axis weight $jta$,

$$
Q_{kI_t,kI_t}=t^2a^2|H_k|^2-2ta\Re(j\overline d H_k).
$$

The nonzero within-user pairs lie on the same axis. Their coefficients, for weights $(8a,4a)$, $(8a,2a)$, and $(4a,2a)$, are respectively

$$
64a^2|H_k|^2=\frac{32}{49}|H_k|^2,\qquad
32a^2|H_k|^2=\frac{16}{49}|H_k|^2,\qquad
16a^2|H_k|^2=\frac{8}{49}|H_k|^2.
$$

Real/imaginary pairs of the same user again have zero coupling. Pairs from different users follow the general $2\Re(\overline{H_kw_b}H_\ell w_c)$ rule. Substituting $H_k=\sqrt P h_k$ gives the factors of $P/49$ in the thesis appendix.

## 6. Conventions and verification

| Modulation | Bits per user | Constant $c$ | Ordered weights $w_b$ |
| --- | ---: | --- | --- |
| BPSK | 1 | $-1$ | $2$ |
| QPSK | 2 | $-(1+j)/\sqrt2$ | $\sqrt2,\ j\sqrt2$ |
| 16-QAM | 4 | $-3b(1+j)$ | $4b,\ 2b,\ 4jb,\ 2jb$ |
| 64-QAM | 6 | $-7a(1+j)$ | $8a,\ 4a,\ 2a,\ 8ja,\ 4ja,\ 2ja$ |

The QAM axes use **binary amplitude labels**, not Gray labels. Their outer corners have unit magnitude; this is *peak* rather than unit-average-energy normalization. Mean symbol energies under uniformly drawn bits are $1$ for BPSK/QPSK, $5/9$ for 16-QAM, and $3/7$ for 64-QAM. Consequently $P_k$ scales the symbol and is not the mean radiated power for the two QAM schemes. This convention is essential when comparing BER under a different normalization.

The implementation creates $A_i$, $d$, and the coefficients directly from the common expansion. [`tests/test_detection.py`](../tests/test_detection.py) enumerates candidate bits for every modulation and checks that the QUBO energy **including $E_0$** agrees with the original complex residual. It also checks that exhaustive ML and the QUBO have the same minimizing bit vector. Run it with:

```bash
python -m unittest discover -s tests -v
```

For the thesis's original fully expanded expressions, see [`tex/Chapter3/ee599-chapter3.tex`](../tex/Chapter3/ee599-chapter3.tex) and [`tex/Appendix1/appendix1.tex`](../tex/Appendix1/appendix1.tex).
