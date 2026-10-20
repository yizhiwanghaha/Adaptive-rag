# Default online launcher. Reads the user's parent .env inside the Python process.
# For intentionally offline tests, use offline-env.ps1 instead.
param([int]$Port = 8001)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Push-Location $projectRoot
try {
    . (Join-Path $PSScriptRoot 'offline-env.ps1')
    $env:ADAPTIVE_RAG_PORT = [string]$Port
    $onlineStartup = @'
import os
from pathlib import Path

from dotenv import dotenv_values
import uvicorn

source = Path.cwd().parent / ".env"
values = dotenv_values(source, interpolate=False) if source.is_file() else {}
mapping = {
    "LLM_API_KEY": "DEEPSEEK_API_KEY",
    "LLM_MODEL_ID": "DEEPSEEK_MODEL",
    "LLM_BASE_URL": "DEEPSEEK_BASE_URL",
}
missing = [name for name in mapping if not values.get(name)]
if missing:
    raise SystemExit("Missing parent LLM configuration fields: " + ", ".join(missing))
for name, target in mapping.items():
    os.environ[target] = values[name]
os.environ["LLM_TIMEOUT_SECONDS"] = "90"
os.environ["LLM_MAX_RETRIES"] = "1"
print("Online DeepSeekProvider enabled from parent configuration; local model weights remain disabled.", flush=True)
uvicorn.run("app.asgi:app", host="127.0.0.1", port=int(os.environ["ADAPTIVE_RAG_PORT"]))
'@
    & (Join-Path $projectRoot '.venv/Scripts/python.exe') -c $onlineStartup
    $serverExitCode = $LASTEXITCODE
}
finally {
    Pop-Location
}
exit $serverExitCode
