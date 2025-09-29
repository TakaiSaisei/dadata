# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-01-25

### Added
- Secure logging system with automatic filtering of sensitive data
- `SecureLogger` class that extends Ruby's Logger to sanitize sensitive information
- `SensitiveData` module for handling sensitive data in logs and error messages
- Connection pooling for improved performance
- New configuration options:
  - `connection_pool_size` for controlling concurrent connections
  - `connection_pool_timeout` for connection pool timeout
  - `log_level` for setting logging verbosity
  - Custom logger support with automatic secure wrapping

### Changed
- **BREAKING**: All loggers are now automatically wrapped in `SecureLogger`
- **BREAKING**: Configuration syntax changed from hash-style to method calls
- Improved HTTP connection handling with persistent connections
- Enhanced error handling with sanitized error messages
- Updated documentation with security best practices

### Security
- Automatic filtering of sensitive headers (Authorization, X-Secret, API-Key)
- Secure handling of API keys and secrets in logs
- Protection against accidental exposure of sensitive data in error messages

## [1.1.2] - 2024-01-26

### Changed
- Updated Ruby version requirement to >= 3.3.0
- Updated development dependencies to their latest versions
- Improved code formatting and alignment in test files
- Enhanced RuboCop configuration with additional rules and extensions
- Added warning suppression for third-party gem warnings in test suite
- Replaced OpenStruct with Struct in tests for better performance

### Fixed
- Fixed method redefinition warnings in generator tests
- Fixed API error handling in tests to use correct error message assertions
- Fixed connection error tests to properly test different network failure scenarios
- Fixed initializer generator tests to match actual template content
- Fixed test assertions to use proper configuration syntax
- Fixed test warnings related to Rails generator testing
- Fixed non-atomic file operations in generator tests
- Removed unnecessary access modifiers in tests

## [1.1.1] - 2024-01-25

### Fixed
- Fixed API error handling in tests to use correct error message assertions
- Fixed connection error tests to properly test different network failure scenarios
- Fixed initializer generator tests to match actual template content
- Fixed test assertions to use proper configuration syntax
- Fixed test warnings related to Rails generator testing

## [1.1.0] - 2024-01-24

### Added
- Comprehensive test suite for Rails generator
- Support for storing API keys in Rails credentials
- New generator options:
  - `--use-credentials` (default: true) for secure API key storage
  - `--timeout` for configuring request timeout
  - `--suggestions-count` for setting default suggestions limit
- Improved documentation in generator templates
- Type definitions using RBS for all clients
- Bilingual documentation (Russian and English) in README
- Enhanced error handling in initializer templates
- Extended test coverage for initializer generator

### Changed
- Replaced `http` gem with `faraday` for better HTTP handling
- Improved initializer template with better code organization and error handling
- Renamed initializer template to use `.rb.tt` extension for better Rails integration
- Updated Rakefile to include all test files including initializer tests
- Improved code style and fixed RuboCop warnings:
  - Fixed string literals in Gemfile
  - Improved file operations safety in tests
  - Enhanced error handling in API exceptions
  - Fixed code style issues across the codebase

### Fixed
- Proper error classes in initializer templates
- Configuration validation in initializer templates
- Various code style issues and RuboCop warnings

### Security
- Added secure credentials storage option for API keys
- Warning messages when storing API keys directly in initializer
- Improved file operations safety in tests

## [1.0.0] - 2023-05-24

- Initial release
