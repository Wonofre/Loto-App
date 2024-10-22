module.exports = {
    env: {
        es6: true,
        node: true,
    },
    parserOptions: {
        ecmaVersion: 2020,
    },
    extends: [
        "eslint:recommended",
        "google",
    ],
    plugins: [
        "jsdoc",
    ],
    rules: {
        "no-restricted-globals": ["error", "name", "length"],
        "prefer-arrow-callback": "error",
        "quotes": ["error", "double", {"allowTemplateLiterals": true}],
        "max-len": ["error", {"code": 200}],
        "indent": ["error", 4],
        "prefer-const": "error",
        "no-unused-vars": [
            "error",
            {
                "args": "after-used",
                "ignoreRestSiblings": false,
                "varsIgnorePattern": "^_",
                "argsIgnorePattern": "^_",
            },
        ],
        "jsdoc/require-param-description": "off",
        "jsdoc/require-param-type": "off",
        "jsdoc/require-returns-description": "off",
        "jsdoc/require-returns-type": "off",
    },
    overrides: [
        {
            files: ["**/*.spec.*"],
            env: {
                mocha: true,
            },
            rules: {},
        },
    ],
    globals: {},
};
