# Part II.  Approximate Riemann Solvers

In Part II of this book we present a number of *approximate Riemann solvers*.  We have already seen that for many important hyperbolic systems it is possible to work out the exact Riemann solution for arbitrary left and right states.  However, for complicated nonlinear systems, such as the Euler equations (see [Euler](Euler.ipynb)), this exact solution can only be determined by solving a nonlinear system of algebraic equations for the intermediate states and the waves that connect them.  This can be done to arbitrary precision, but only at some computational expense.  The cost of exactly solving a single Riemann problem may seem insignificant, but it can become prohibitively expensive when the Riemann solver is used as a building block in a finite volume method.  In this case a Riemann problem must be solved at every cell edge at every time step.

For example, if we consider a very coarse grid in one space dimension with only 100 cells and take 100 time steps, then 10,000 Riemann problems must be solved.  In solving practical problems in two or three space dimensions it is not unusual to require the solution of billions or trillions of Riemann problems. In this context it can be very important to develop efficient approximate Riemann solvers that quickly produce a sufficiently good approximation to the true Riemann solution.

The following points have helped to guide the development of approximate Riemann solvers:

 - If the solution is smooth over much of the domain, then the jump in states between neighboring cells will be very small (on the order of $\Delta x$, the cell size) for most of the Riemann problems encountered in the numerical solution. Even if the hyperbolic system being studied is nonlinear, for such data the equations can be approximated by a linearization and we have seen that linear Riemann problems can be solved more easily than nonlinear ones.  Rather than solving a nonlinear system of equations by some iterative method, one need only solve a linear system (provided the eigenvalues and eigenvectors of the Jacobian matrix are known analytically, as they often are for practical problems).  In many cases the solution of this linear system can also be worked out analytically and is easy to implement, so numerical linear algebra is not required.  
 
 - In spite of smoothness over much of the domain, in interesting problems there are often isolated discontinuities such as shock waves that are important to model accurately.  So some Riemann problems arising in a finite volume method may have large jumps between the left and right states.  Hence a robust approximate Riemann solver must also handle these cases without introducing too much error.
 
 - But even in the case of large jumps in the data, it may not be necessary or worthwhile to solve the Riemann problem exactly.  The information produced by the Riemann solver goes into a numerical method that updates the approximate solution in each grid cell and the exact  structure of the Riemann solution is lost in the process.

Each chapter in this part of the book illustrates some common approximate Riemann solvers in the context of one of the nonlinear systems studied in part 1.  We focus on two popular approaches to devising approximate Riemann solvers, though these are certainly not the only approaches: linearized solvers and two-wave solvers.

## Finite volume methods

We give a short review of Riemann-based finite volume methods to illustrate what is typically needed from a Riemann solver in order to implement such methods. In one space dimension, a finite volume approximation to the solution $q(x,t_n)$ at the $n$th time step consists of discrete values $Q_j^n$, each of which can be viewed as approximating the cell average of the solution over a grid cell $x_{j-1/2} < x < x_{j+1/2}$ for some discrete grid.   The cell length $\Delta x_j = x_{j+1/2} - x_{j-1/2}$ is often uniform, but this is not required.  Many methods for hyperbolic conservation laws are written in *conservation form*, in which the numerical solution is advanced from time $t_n$ to $t_{n+1} = t_n + \Delta t_n$ by the explicit formula

\begin{align}\label{FVupdate}
Q_j^{n+1} = Q_j^n - \frac{\Delta t_n}{\Delta x_j} (F_{j+1/2}^n - F_{j-1/2}^n),
\end{align}

for some definition of the *numerical flux* $F_{j-1/2}^n$, typically based on $Q_{j-1}^n$ and $Q_j^n$ (and possibly other nearby cell values at time $t_n$).

Dividing (\ref{FVupdate}) by $\Delta t_n$ and rearranging, this form can be viewed as a discretization of $q_t + f(q)_x = 0$, provided the numerical flux is *consistent* with the true flux $f(q)$ in a suitable manner. In particular if the $Q_i$ used in defining $F_{j-1/2}^n$ are all equal to the same value $\bar q$, then $F_{j-1/2}^n$ should reduce to $f(\bar q)$.

A big advantage of using conservation form is that the numerical method is conservative. The sum $\sum \Delta x_j Q_j^n$ approximates the integral $\int q(x,t_n)\,dx$.  Multiplying (\ref{FVupdate}) by $\Delta x_j$ and summing shows that at time $t_{n+1}$ this sum only changes due to fluxes at the boundaries of the region in question (due to cancellation of the flux differences when summing), a property shared with the true solution.  For problems with shock waves, using methods in conservation form is particularly important since nonconservative formulations can lead to methods that converge to discontinuous solutions that look fine but are not correct, e.g. the shock wave might propagate at entirely the wrong speed. 

### Godunov's method

Trying to compute numerical approximations to hyperbolic problems with strong shock waves is challenging because of the discontinuities in the solution --- classical interpretations of $(F_{j+1/2}^n - F_{j-1/2}^n)/\Delta x_j \approx \partial f/ \partial x$ break down, oscillations near discontinuities often appear, and methods can easily go catastrophically unstable.

The landmark paper of Godunov <cite data-cite="godunov"><a href="riemann.html#godunov">(Godunov 1959)</a></cite> was the first to suggest using the solution to Riemann problems in defining the numerical flux: $F_{j-1/2}^n$ is obtained by evaluating $f(Q_{j-1/2}^*)$, where $Q_{j-1/2}^*$ is the Riemann solution evaluated along the ray $x/t = 0$ after the standard Riemann problem is solved between states $q_\ell=Q_{j-1}^n$ and $q_r=Q_j^n$ (with the discontinuity placed at $x=t=0$ as usual in the definition of the Riemann problem). If the numerical solution is now defined as a piecewise constant function with value $Q_j^n$ in the $j$th cell at time $t_n$, then the exact solution takes this value along the cell interface $x_{j-1/2}$ for sufficiently small later times $t > t_n$ (until waves from other cell interfaces begin to interact).

The classic Godunov method was developed for gas dynamics and the exact Riemann solution was used, but since only one value is used from this solution and the rest of the structure is thrown away, it is natural to use some *approximate Riemann solver* that more cheaply estimates $Q_{j-1/2}^*$.  The approximations discussed in the next few chapters are often suitable.

Godunov's method turns out to be very robust -- because the shock structure of the solution is used in defining the interface flux, the method generally remains stable provided that the *Courant-Friedrichs-Lewy (CFL) Condition* is satisfied, which restricts the allowable time step relative to the cell sizes and wave speeds by requiring that no wave can pass through more than one grid cell in a single time step.  This is clearly a necessary condition for convergence of the method, based on domain of dependence arguments, and for Godunov's method (with the exact solver) this is generally sufficient as well, as verified in countless simulations (though seemingly impossible to prove in complete generality for nonlinear systems of equations).  When the exact solution is replaced by an approximate solution, the method may not work as well, and so some care has to be used in defining a suitable approximation.


### High-resolution methods

In spite of its robustness, Godunov's method is seldom used as just described because the built-in *numerical viscosity* that gives it robustness also leads to very smeared out solutions, particularly around discontinuities, unless a very fine computational grid is used.  For the advection equation, Godunov's method reduces to the standard "first-order upwind" method and in general it is only first order accurate even on smooth solutions.

A wide variety of higher order Godunov-type (i.e., Riemann solver based) methods have been developed.  One approach first reconstructs better approximations to the solution at each time from the states $Q_j^n$, e.g. a piecewise polynomial that is linear  or quadratic in each grid cell rather than constant, and then uses the states from these polynomials evaluated at the cell interfaces to define the Riemann problems.  Another approach, used in the "wave propagation methods" developed in <cite data-cite="fvmhp"><a href="riemann.html#fvmhp">(LeVeque, 2002)</a></cite>, for example, is to take the waves that come out of the Riemann solution based on the original data to also define second order correction terms.  In either case some *limiters* must generally be applied in order to avoid nonphysical oscillations in solutions, particularly when the true solution has discontinuities.  There is a vast literature on such methods; see for example many of the books cited in the [Preface](Preface.ipynb).  For our present purposes the main point is that an approximate Riemann solver is a necessary ingredient in many methods that are commonly used to obtain high-resolution approximations to hyperbolic PDEs.

## Notation and structure of approximate solutions

We consider a single Riemann problem with left state $q_\ell$ and right state $q_r$.  These states might be $Q_{j-1}^n$ and $Q_j^n$ for a typical interace when using Godunov's method, or other states defined from them, e.g. after doing a polynomial reconstruction.  At any rate, from now on we will not discuss the numerical methods or the grid in its totality, but simply focus on how to define an approximate Riemann solution based an an arbitrary pair of states.  The resulting "interface solution" and "interface flux" will be denoted simply by $Q^*$ and $F^*$, respectively, as approximations to the Riemann solution and flux along $x/t =0$ in the similarity solution.

The Riemann solution gives a resolution of the jump $\Delta q = (q_r - q_\ell)$ into a set of propagating waves.  In both of the approaches described below, the approximate Riemann solution consists entirely of traveling discontinuities, i.e., there are no rarefaction waves in the approximate solution, although there may be a discontinuity that approximates such a wave.  One should rightly worry about whether the approximate solution generated with such a method will satisfy the required entropy condition and end up with rarefaction waves where needed rather than entropy-violating shocks, and we address this to some extent in the examples in the following chapters.  It is important to remember that we are discussing the approximate solver that will be used *at every grid interface* in every time step, and the numerical viscosity inherent in the numerical method can lead to rarefactions in the overall numerical approximation even if each approximate Riemann solution lacks rarefactions.  Nonetheless some care is needed, particularly in the case of *transonic* rarefactions, as we will see.

Following <cite data-cite="fvmhp"><a href="riemann.html#fvmhp">(LeVeque, 2002)</a></cite>, we refer to these traveling discontinuities as *waves* and denote them by ${\cal W}_p \in {\mathbb R}^m$, where the index $p$ denotes the characteristic family and typically ranges from $1$ to $m$ for a system of $m$ equations, although in an approximate solver the number of waves may be smaller (or possibly larger).  At any rate, they always have the property that
\begin{align}\label{Wsum}
q_r - q_\ell = \sum_{p} {\cal W}_p.
\end{align}
For each wave, the approximate solver must also give a wave speed $s_p \in{\mathbb R}$.  For a linear system such as acoustics, the true solution has this form with the $s_p$ being eigenvalues of the coefficient matrix and each wave is a corresponding eigenvector, as described in [Acoustics](Acoustics.ipynb).  One class of approximate Riemann solvers descussed below is based on approximating a nonlinear problem by a linearization locally at each interface.

Once a set of waves and speeds have been defined, we can define an interface flux as follows: the waves for which $s_p < 0$ are traveling to the left while those with $s_p>0$ are traveling to the right, and so as an interface flux we could use $f(Q^*)$, where $Q^*$ is defined by either
$$
Q^* = q_\ell + \sum_{p: s_p < 0} {\cal W}_p.
$$
or
$$
Q^* = q_r - \sum_{p: s_p > 0} {\cal W}_p.
$$
These two expressions give the same value for $Q^*$ unless there is a wave with $s_p=0$, in which case they could be different if the corresponding ${\cal W}_p$ is nonzero.  However, if we are using the *exact* Riemann solution (e.g. for a linear system or a nonlinear problem in which the solution consists only of shock waves), then a stationary discontinuity with $s_p=0$ must have no jump in flux across it (by the Rankine-Hugoniot condition) and so even if the two values of $Q^*$ differ, the flux $f(Q^*)$ is uniquely defined.  For an approximate Riemann solution this might not be true.

Another way to define the interface flux $F^*$ would be as
\begin{align}\label{Fstar}
F^* = f(q_\ell) + \sum_{p: s_p \leq 0} s_p{\cal W}_p
= f(q_r) - \sum_{p: s_p \geq 0} s_p{\cal W}_p
\end{align}
suggested by the fact that this is the correct flux along $x/t = 0$ for a linear system $f(q)=Aq$ or for a nonlinear system with only shocks in the solution; in these cases the Rankine-Hugoniot condition implies that $s_p{\cal W}_p$ is equal to the jump in flux across each wave.  Note that in this expression the terms in the sum for $s_p=0$ drop out so the two expressions always agree.  

The wave propagation algorithms described in <cite data-cite="fvmhp"><a href="riemann.html#fvmhp">(LeVeque, 2002)</a></cite> and implemented in Clawpack use a form of Godunov's method based on the sums appearing in (\ref{Fstar}), called "fluctuations", to update the neighboring cell averages, rather than the flux difference form.  In these methods  the waves and speeds which are further used (after applying a limiter to the waves) to obtain the high-resolution corrections.  An advantage of working with fluctuations, waves, and speeds rather than interface fluxes is that these quantities often make sense also for *non-conservative hyperbolic systems,* such as the variable coefficient linear problem $q_t + A(x)q_x = 0$, for which there is no "flux function".  A Riemann problem is defined by prescribing matrices $A_\ell$ and $A_r$ along with the initial data $q_\ell$ and $q_r$, for example by using the material properties in the grid cells to the left and right of the interface for acoustics through a heterogeneous material.  The waves are then naturally defined using the eigenvectors of $A_\ell$ corresponding to negative eigenvalues for the left-going waves, and using eigenvectors of $A_r$ corresponding to positive eigenvalues for the right-going waves.  See <cite data-cite="fvmhp"><a href="riemann.html#fvmhp">(LeVeque, 2002)</a></cite> for more details.

Updating cell averages by fluctuations rather than flux differencing will give a conservative method (when applied to a hyperbolic problem in conservation form) only if the waves and speeds in the approximate solver satisfy
\begin{align}
\label{adqdf}
\sum_{p=1}^m s_p {\cal W}_p = f(q_r) - f(q_\ell).
\end{align}
This is a natural condition to require of our approximate Riemann solvers in general, even though the flux-differencing form (\ref{FVupdate}) always leads to a conservative method, since this is satisfied by the exact solution in cases where it consists only of discontinuities and each wave satisfies the Rankine-Hugoniot condition.  When (\ref{adqdf}) is satisfied we say the approximate solver is conservative.

## Linearized Riemann solvers 
Consider a nonlinear system $q_t + f(q)_x = 0$. If $q_\ell$ and $q_r$ are close to each other, as is often the case over smooth regions of a more general solution, then the nonlinear system can be approximated by a linear problem of the form $q_t + \hat A q_x = 0$.  The coefficient matrix $\hat A$ should be some approximation to  $f'(q_\ell) \approx f'(q_r)$ in the case where $\|q_\ell-q_r\|$ is small.  The idea of a general linearized Riemann solver is to define a matrix $\hat A(q_\ell, q_r)$ that has this property but also makes sense as an approximation in the case when $\|q_\ell-q_r\|$ is not small.  For many nonlinear systems there is a *Roe linearization*, a particular function that works works very well based on ideas introduced originally by Roe <cite data-cite="Roe1981"><a href="riemann.html#Roe1981">(Roe, 1981)</a></cite>.  For systems such as the shallow water equations or the Euler equations, there are closed-form expressions for the eigenvalues and eigenvectors of $\hat A$ and the solution of the linearized Riemann problem, leading to efficient solvers.  These will be presented in the next few chapters.

## Two-wave solvers 
Since the Riemann solution impacts the overall numerical solution only based on how it modifies the two neighboring solution values, it seems reasonable to consider approximations in which only a single wave propagates in each direction.  The solution will have a single intermediate state $q_m$ such that ${\cal W}_1 = q_m - q_\ell$ and ${\cal W}_2 = q_r-q_m$.  There are apparently $m+2$ values to be determined: the middle state $q_m \in {\mathbb R}^m$ and the speeds $s_1, s_2$.  In order for the approximate solver to be conservative, it must satisfy (\ref{adqdf}), and hence the $m$ conditions  
\begin{align}
f(q_r) - f(q_\ell) = s_1 {\cal W}_1 + s_2 {\cal W}_2.
\end{align}  
This can be solved for the middle state to find  
\begin{align}  \label{AS:middle_state}
q_m = \frac{f(q_r) - f(q_\ell) - s_2 q_r + s_1 q_\ell}{s_1 - s_2}.
\end{align}  
It remains only to specify the wave speeds, and it is in this specification that the various two-wave solvers differ.  In the following sections we briefly discuss the choice of wave speed for a scalar problem; the choice for systems will be elaborated in subsequent chapters.

Typically $s_1 < 0 < s_2$ and so the intermediate state we need is $Q^* = q_m$ and $F^* = f(Q^*)$.  However, in some cases both $s_1$ and $s_2$ could have the same sign, in which case $F^*$ is either $f(q_\ell)$ or $f(q_r)$.

In addition to the references provided below, this class of solvers is also an ingredient in the so-called *central schemes*.  Due to the extreme simplicity of two-wave solvers, the resulting central schemes are often even referred to as being "Riemann-solver-free".

### Lax-Friedrichs (LF) and local-Lax-Friedrichs (LLF)

The simplest such solver is the *Lax-Friedrichs method*, in which it is assumed that both waves have the same speed, in opposite directions:
$$-s_1 = s_2 = a,$$
where $a\ge 0$.  Then (\ref{AS:middle_state}) becomes
$$q_m = -\frac{f(q_r) - f(q_\ell)}{2a} + \frac{q_r + q_\ell}{2}.$$
In the original Lax-Friedrichs method, the wave speed $a$ is taken to be the same in every Riemann problem over the entire grid; in the *local Lax Friedrichs (LLF) method*, a different speed $a$ may be chosen for each Riemann problem.

For stability reasons, the wave speed should be chosen at least as large as the fastest wave speed appearing in the true Riemann solution.  However, choosing a wave speed that is too large leads to excess diffusion.  For the LLF method (originally due to Rusanov), the wave speed is chosen as
$$a(q_r, q_\ell) = \max(|f'(q)|)$$  
where the maximum is taken over all values of $q$ between $q_r$ and $q_\ell$.  This ensures stability, but may still introduce substantial damping of slower waves.

### Harten-Lax-van Leer (HLL)

A less dissipative solver can be obtained by allowing the left- and right-going waves to have different speeds.
This approach was developed in <cite data-cite="HLL"><a href="riemann.html#HLL">(Harten, Lax, and van Leer)</a></cite>.  The solution is then determined by (\ref{AS:middle_state}).  In the original HLL solver, it was suggested to again to use speeds that bound the possible speeds occurring in the true solution.  For a scalar problem, this translates to  
\begin{align*}
s_1 & = \min(f'(q)) \\
s_2 & = \max(f'(q)),
\end{align*}  
where again the minimum and maximum are taken over all values between $q_r$ and $q_\ell$.  Many refinements of this choice have been proposed in the context of systems of equations, some of which will be discussed in later chapters.


```python

```
