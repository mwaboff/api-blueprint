#!/usr/bin/env bash
# Detects the backend framework of the current project.
# Usage: detect-framework.sh [project-root]
# Output: JSON with language, framework, build_tool, confidence, supported

set -euo pipefail

PROJECT_ROOT="${1:-.}"

detect() {
    local framework=""
    local language=""
    local build_tool=""
    local confidence="low"

    # --- Java / Spring Boot ---
    if [[ -f "$PROJECT_ROOT/pom.xml" ]]; then
        build_tool="maven"
        language="java"
        if grep -q "spring-boot" "$PROJECT_ROOT/pom.xml" 2>/dev/null; then
            framework="spring-boot"
            confidence="high"
        fi
    elif [[ -f "$PROJECT_ROOT/build.gradle" ]] || [[ -f "$PROJECT_ROOT/build.gradle.kts" ]]; then
        build_tool="gradle"
        language="java"
        local gradle_file=""
        [[ -f "$PROJECT_ROOT/build.gradle" ]] && gradle_file="$PROJECT_ROOT/build.gradle"
        [[ -f "$PROJECT_ROOT/build.gradle.kts" ]] && gradle_file="$PROJECT_ROOT/build.gradle.kts"
        if [[ -n "$gradle_file" ]] && grep -q "spring-boot\|org.springframework.boot" "$gradle_file" 2>/dev/null; then
            framework="spring-boot"
            confidence="high"
        fi
    fi

    # --- Python / FastAPI / Django / Flask ---
    if [[ -z "$language" ]]; then
        local py_deps_file=""
        if [[ -f "$PROJECT_ROOT/pyproject.toml" ]]; then
            py_deps_file="$PROJECT_ROOT/pyproject.toml"
            build_tool="pyproject"
            language="python"
        elif [[ -f "$PROJECT_ROOT/requirements.txt" ]]; then
            py_deps_file="$PROJECT_ROOT/requirements.txt"
            build_tool="pip"
            language="python"
        elif [[ -f "$PROJECT_ROOT/setup.py" ]]; then
            py_deps_file="$PROJECT_ROOT/setup.py"
            build_tool="setuptools"
            language="python"
        fi

        if [[ -n "$py_deps_file" ]]; then
            if grep -qi "fastapi" "$py_deps_file" 2>/dev/null; then
                framework="fastapi"
                confidence="high"
            elif grep -qi "django" "$py_deps_file" 2>/dev/null; then
                framework="django"
                confidence="high"
            elif grep -qi "flask" "$py_deps_file" 2>/dev/null; then
                framework="flask"
                confidence="high"
            fi
        fi
    fi

    # --- Node.js / Express / NestJS / Fastify ---
    if [[ -z "$language" ]] && [[ -f "$PROJECT_ROOT/package.json" ]]; then
        language="javascript"
        build_tool="npm"
        if [[ -f "$PROJECT_ROOT/yarn.lock" ]]; then
            build_tool="yarn"
        elif [[ -f "$PROJECT_ROOT/pnpm-lock.yaml" ]]; then
            build_tool="pnpm"
        fi
        if grep -q '"typescript"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
            language="typescript"
        fi
        if grep -q '"express"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
            framework="express"
            confidence="high"
        elif grep -q '"@nestjs/core"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
            framework="nestjs"
            confidence="high"
        elif grep -q '"fastify"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
            framework="fastify"
            confidence="high"
        fi
    fi

    # --- Go ---
    if [[ -z "$language" ]] && [[ -f "$PROJECT_ROOT/go.mod" ]]; then
        language="go"
        build_tool="go-modules"
        if grep -q "gin-gonic" "$PROJECT_ROOT/go.mod" 2>/dev/null; then
            framework="gin"
            confidence="high"
        elif grep -q "gorilla/mux" "$PROJECT_ROOT/go.mod" 2>/dev/null; then
            framework="gorilla-mux"
            confidence="high"
        elif grep -q "go-chi" "$PROJECT_ROOT/go.mod" 2>/dev/null; then
            framework="chi"
            confidence="high"
        fi
    fi

    # --- Rust ---
    if [[ -z "$language" ]] && [[ -f "$PROJECT_ROOT/Cargo.toml" ]]; then
        language="rust"
        build_tool="cargo"
        if grep -q "actix-web" "$PROJECT_ROOT/Cargo.toml" 2>/dev/null; then
            framework="actix-web"
            confidence="high"
        elif grep -q "axum" "$PROJECT_ROOT/Cargo.toml" 2>/dev/null; then
            framework="axum"
            confidence="high"
        elif grep -q "rocket" "$PROJECT_ROOT/Cargo.toml" 2>/dev/null; then
            framework="rocket"
            confidence="high"
        fi
    fi

    # --- Ruby / Rails / Sinatra ---
    if [[ -z "$language" ]] && [[ -f "$PROJECT_ROOT/Gemfile" ]]; then
        language="ruby"
        build_tool="bundler"
        if grep -q "rails" "$PROJECT_ROOT/Gemfile" 2>/dev/null; then
            framework="rails"
            confidence="high"
        elif grep -q "sinatra" "$PROJECT_ROOT/Gemfile" 2>/dev/null; then
            framework="sinatra"
            confidence="high"
        fi
    fi

    # --- C# / ASP.NET ---
    if [[ -z "$language" ]]; then
        local csproj_file=""
        csproj_file=$(find "$PROJECT_ROOT" -maxdepth 2 -name "*.csproj" -print -quit 2>/dev/null || true)
        if [[ -n "$csproj_file" ]]; then
            language="csharp"
            build_tool="dotnet"
            if grep -q "Microsoft.AspNetCore" "$csproj_file" 2>/dev/null; then
                framework="aspnet"
                confidence="high"
            fi
        fi
    fi

    # --- Fallback ---
    if [[ -z "$language" ]]; then
        language="unknown"
        framework="unknown"
        confidence="none"
    fi

    local supported="false"
    if [[ "$framework" == "spring-boot" ]]; then
        supported="true"
    fi

    cat <<EOF
{
  "language": "$language",
  "framework": "${framework:-unknown}",
  "build_tool": "${build_tool:-unknown}",
  "confidence": "$confidence",
  "supported": $supported
}
EOF
}

detect
