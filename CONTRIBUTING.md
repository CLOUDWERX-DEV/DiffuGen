# Contributing to DiffuGen

Thank you for your interest in contributing to DiffuGen! This document provides guidelines and instructions for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Pull Requests](#pull-requests)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)
- [Community](#community)

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to [sysop@cloudwerx.dev](mailto:sysop@cloudwerx.dev).

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally
3. Set up the development environment as described in the [Development Setup](#development-setup) section
4. Create a branch for your changes
5. Make your changes
6. Submit a pull request

## How to Contribute

### Reporting Bugs

If you find a bug in the project, please create an issue on GitHub with the following information:

- A clear, descriptive title
- Steps to reproduce the issue
- Expected behavior
- Actual behavior
- Screenshots or logs if applicable
- Environment information (OS, Python version, etc.)

### Suggesting Enhancements

If you have an idea for an enhancement, please create an issue on GitHub with the following information:

- A clear, descriptive title
- A detailed description of the enhancement
- The motivation behind the enhancement
- Any potential implementation details
- Any potential drawbacks or challenges

### Pull Requests

1. Update the README.md with details of changes if applicable
2. Update the documentation if applicable
3. The PR should work on all supported platforms
4. Ensure all tests pass
5. Follow the coding standards

## Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/CLOUDWERX-DEV/diffugen.git
   cd diffugen
   ```

2. Create and activate a virtual environment:
   ```bash
   python -m venv diffugen_env
   source diffugen_env/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install development dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Set up pre-commit hooks:
   ```bash
   pre-commit install
   ```

## Coding Standards

- Follow PEP 8 style guide for Python code
- Use meaningful variable and function names
- Write docstrings for all functions, classes, and modules
- Keep functions small and focused on a single task
- Use type hints where appropriate
- Comment complex code sections

## Testing

- Write tests for all new features and bug fixes
- Ensure all tests pass before submitting a pull request
- Run tests using pytest:
  ```bash
  pytest
  ```

## Documentation

- Update documentation for all new features and changes
- Follow the existing documentation style
- Use clear, concise language
- Include examples where appropriate

## Community

- Join our [Discord server](https://discord.gg/SvZFuufNTQ) for discussions
- Follow us on [X](https://twitter.com/cloudwerxlab) for updates
- Subscribe to our [newsletter](https://cloudwerx.dev/newsletter) for major announcements

Thank you for contributing to DiffuGen! 