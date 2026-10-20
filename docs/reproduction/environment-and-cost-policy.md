# 环境复用、配置来源与费用控制

补充核对日期：2026-10-20。此文仅同步脱敏事实与执行规则，不发布个人 API endpoint、model ID 或任何密钥。完整环境清单与 84 个唯一 Python distribution 版本保留在本地 `.local/environment-inventory.md` / `.local/installed-packages.json`。

## 环境与模型事实

- 复用现有 Python 3.12.9、uv 0.11.7、Node 24.12.0、npm 11.6.2、Git 2.53.0.windows.2；项目独立 `.venv`。Kotaemon/Hercules 配置和环境不动。
- FastAPI、LangGraph、SQLAlchemy、pytest 等基础/dev 依赖已装；torch、sentence_transformers、modelscope、unstructured 尚缺。缺失的是可选模型/解析扩展，不是离线 API 的阻碍。
- 当前仍为 OfflineLLMProvider、HashEmbeddingProvider 和 lexical Rerank；中文 BGE 与 Cross-Encoder 未真正加载。本项目没有下载模型权重。已查工作区及常用缓存路径，未找到两个目标权重；未声称扫描所有磁盘。
- 找到既有英文 BGE ONNX 量化缓存，约 64.07 MiB；与目标中文 SentenceTransformer 及 Cross-Encoder 的语言、格式和用途不同，不直接替换。
- 项目、环境和日志在 D 盘；已有用户级 uv/npm/pip 缓存也在 D 盘，后续优先复用。阶段 1 的独立缓存保留，不迁移、合并或清空。离线脚本当前固定阶段 1 缓存路径，继续安装时可在 dot-source 之后设置进程级缓存路径；本轮未改启动脚本。
- 既有全套 pytest 162 passed / 0 failed/skipped，前端 3 tests passed/build PASS。本轮重新 GET 本地 health 成功；原始测试结果沿用事实卡，不冒充新跑的测试。

## LLM 配置接入

用户指定父目录 `.env` 为在线 LLM 的唯一配置来源。文件实际使用 `LLM_API_KEY / LLM_MODEL_ID / LLM_BASE_URL`；上游 `Settings` 默认读取当前工作目录 `.env`，只认 `DEEPSEEK_API_KEY / DEEPSEEK_MODEL / DEEPSEEK_BASE_URL`。即使直接指定父文件，也不会自动识别 `LLM_*`。配置文件仅脱敏读取，未修改或复制密钥。

用户后续已同意进程级映射方案并授权持续使用此中转站。新增 `scripts/repro/start-api.ps1`：先应用无本地模型的基础环境，再在 Python 子进程读取父配置并映射三个字段；不创建项目 `.env`，不改父配置、settings 或 provider 业务源码。离线脚本会清空 Key，因此在线凭据映射位于它之后。缺失必需字段则停止启动，不静默退回离线。

在仓库根目录执行 `./scripts/repro/start-api.ps1`，默认绑定 `127.0.0.1:8001`，可用 `-Port` 指定其他本地端口。仅此启动入口默认启用真实 LLM；直接运行原生 uvicorn 不会自动识别父目录 LLM_*。既有 offline-env.ps1 与 HTTP 离线重放脚本保留，用于不付费的确定性回归；不要把要求 Token=0 的离线 smoke 脚本用于在线端点。

服务超时为 90 秒，每次模型调用最多尝试 1 次。运行中修改父配置需要重启此启动入口才能生效。原 8000 离线实例仍保留；停止旧进程及后台创建新进程曾被工具自动策略拦截，因此当前在线实例由工具管理的前台 session 托管在 8001，未替换其他服务。前端构建产物由同端口 FastAPI 提供，使用 8001 即可；Vite 开发配置仍代理 8000，不属于本次修改范围。

已用假密钥和 httpx.MockTransport 离线验证 `/v1/chat/completions` 拼接、JSON response_format 请求及 choices/usage 解析；退出 0，真实网络请求 0。该结果不证明实际第三方 endpoint 或配置 model ID 兼容。日志仅本地 `.local/logs/llm-compatibility-offline.log`。

## 费用与授权（后续用户指令已更新）

1. 初次环境审计为免费离线检查，实际外部模型请求为 0；此后用户明确要求“之后都启用，价格我能承受”，作为本项目该中转站的持续 API 授权，不再逐次询问费用批准。
2. 后续日常复现和验证默认通过上述在线启动器使用父配置的服务和模型，按需小范围调用；现有自动化测试仍保持离线，避免无必要批量调用。
3. 配置是第三方兼容服务，不能直接套用官方 DeepSeek 价目。记录 Token 和代理返回用量；没有已核实的单位和价目，不编造人民币金额。持续 API 授权不包含购买额度、付费云资源或公网部署。
4. 已真实尝试 16 输出 Token JSON 探针，返回后 JSON 解析失败；扩大为 128 后收到 HTTP 200、有效 JSON，finish_reason=stop。后一次代理报告 prompt 4463 / completion 6 / total 4469 Token、credit=0.01；credit 单位未知。首次失败没有有效用量记录，不能声称已知本次总账单。
5. 一次 chat 可能涉及分类、路由、生成、检查等多次模型请求；聊天响应 token_usage 不保证覆盖各节点所有调用。BGE/精排仍为 Hash/Lexical，真实 LLM 成功不代表本地模型加载成功。
6. 不自动购买额度、创建付费云资源或公网部署。模型下载及额外业务源码改动仍按原授权边界处理。

此补充不启动阶段 2，不改变阶段 1 的离线口径或任何上游业务源码。

## 在线启动实际验收

- `./scripts/repro/start-api.ps1` 已实际启动在线实例，`127.0.0.1:8001` 的 health / ready 均 HTTP 200。
- 使用模拟身份 `u_online_smoke` 请求“你好”：`POST /api/v1/chat` 返回 200、`strategy=direct`、有效问候回答；`trace_id=tr_2081829715e34d96a158c500ec8e2367`，墙钟约 36.33s。
- 响应回答环节用量为 prompt 4617 / completion 130 / total 4747 Token；分类和路由调用不完整包含在此字段中，不能据此汇总总账单。本次没有批量线上 Evaluation。
- 启动脚本 PowerShell 与内嵌 Python 语法检查通过；`python -m pytest -q tests/e2e/test_chat_api.py tests/unit/test_cli.py --junitxml=.local/logs/online-launcher-regression.xml`：退出 0，9 passed / 0 failed/skipped，3.85s（1 warning）。测试继续使用离线 conftest。
- 原始 probe、诊断和 HTTP 结果仅本地 `.local/logs/online-provider-probe.json`、`online-proxy-diagnostic.json`、`online-api-smoke.json`；不上传密钥、个人服务地址或完整敏感日志。
- 在线 RAG 质量、多跳、真实工具调用和本地 BGE/精排仍未验证。本次仅完成在线 Provider 与 DIRECT 的实际验收。
