## Frontend design skills: precedence

Several installed design skills overlap. Apply them in this order and do not stack conflicting rules:

1. **Impeccable** (`impeccable`) is the primary design authority for all frontend work: layout, typography, color, spacing, polish, and anti-pattern checks.
2. **Taste Skill** (`design-taste-frontend`): use its variance / motion / density dials only when the user explicitly asks for a specific level. Otherwise do not apply its defaults.
3. **frontend-design** is the fallback baseline, used only where Impeccable is silent.

When two skills disagree, the higher-ranked one wins; do not blend or average their rules. Specialist skills (Emil Kowalski animation, GSAP, Three.js, ibelick fixing-*/baseline-ui, UI UX Pro Max, Vercel web-design-guidelines) are references for their own domain and must not override the ranking above on general design direction.
