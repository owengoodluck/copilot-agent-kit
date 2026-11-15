/**
 * Generic dependency rules that need no knowledge of your project layout.
 * Copy to the repo root as `.dependency-cruiser.js`.
 *
 * Tier A (enabled below): violations are wrong in any codebase.
 * Tier B (commented at the bottom): needs your layer names. See README.md.
 *
 * Run:  npx depcruise src --config .dependency-cruiser.js
 * Fail: exit code != 0 when any `error` rule is violated.
 */
module.exports = {
  forbidden: [
    {
      name: 'no-circular',
      severity: 'error',
      comment: 'Circular imports make module init order unpredictable and break tree shaking.',
      from: {},
      to: { circular: true },
    },
    {
      name: 'not-to-unresolvable',
      severity: 'error',
      comment: 'An import that resolves to nothing is a broken build waiting to happen.',
      from: {},
      to: { couldNotResolve: true },
    },
    {
      name: 'no-non-package-json',
      severity: 'error',
      comment: 'Importing a package that is not in package.json works locally and breaks in CI.',
      from: {},
      to: { dependencyTypes: ['npm-no-pkg', 'npm-unknown'] },
    },
    {
      name: 'not-to-dev-dep',
      severity: 'error',
      comment: 'Production code must not import devDependencies; they are absent in production installs.',
      from: { pathNot: '\\.(test|spec|bench|stories)\\.[jt]sx?$' },
      to: { dependencyTypes: ['npm-dev'] },
    },
    {
      name: 'no-test-in-production',
      severity: 'error',
      comment: 'Production code must not import test helpers or fixtures.',
      from: { pathNot: '\\.(test|spec|bench|stories)\\.[jt]sx?$' },
      to: { path: '\\.(test|spec|bench|stories)\\.[jt]sx?$|/__tests__/|/__mocks__/|/fixtures?/' },
    },
    {
      name: 'no-duplicate-dep-types',
      severity: 'warn',
      comment: 'A dependency declared in both dependencies and devDependencies.',
      from: {},
      to: { moreThanOneDependencyType: true, dependencyTypesNot: ['type-only'] },
    },
  ],

  options: {
    doNotFollow: { path: 'node_modules' },
    // Do NOT add node_modules to `exclude`: it removes the dependency edges as well,
    // which silently disables `not-to-dev-dep` and `no-non-package-json`.
    exclude: {
      path: '/dist/|/build/|/coverage/|\\.min\\.js$',
    },
    tsPreCompilationDeps: true,
    enhancedResolveOptions: {
      exportsFields: ['exports'],
      conditionNames: ['import', 'require', 'node', 'default'],
    },
    reporterOptions: {
      text: { highlightFocused: true },
    },
  },

  // ---------------------------------------------------------------------------
  // Tier B: add these once you know your layers. Replace the paths first.
  //
  // {
  //   name: 'no-reverse-layer',
  //   severity: 'error',
  //   from: { path: '^src/(api|service)' },
  //   to: { path: '^src/repository/' },
  // },
  // {
  //   name: 'api-not-in-data-layer',
  //   severity: 'error',
  //   from: { path: '^src/repository/' },
  //   to: { path: '^src/api/' },
  // },
  // ---------------------------------------------------------------------------
}
