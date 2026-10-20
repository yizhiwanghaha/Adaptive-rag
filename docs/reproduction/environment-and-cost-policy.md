# 环境复用、配置来源与费用控制

补充核对日期：2026-10-20。此文仅同步脱敏事实与执行规则，不发布个人 API endpoint、model ID 或任何密钥。完整环境清单与 84 个唯一 Python distribution 版本保留在本地 `.local/environment-inventory.md` / `.local/installed-packages.json`。

## 环境与模型事实

- 复用现有 Python 3.12.9、uv 0.11.7、Node 24.12.0、npm 11.6.2、Git 2.53.0.windows.2；项目独立 `.venv`。Kotaemon/Hercules 配置和环境不动。
- FastAPI、LangGraph、SQLAlchemy、pytest 等基础/dev 依赖已装；torch、sentence_transformers、modelscope、unstructured 尚缺。缺失的是可选模型/解析扩展，不是离线 API 的阻碍。
- 当前仍为 OfflineLLMProvider、HashEmbeddingProvider 和 lexical Rerank；中文 BGE 与 Cross-Encoder 未真正加载。本项目没有下载模型权重。已查工作区及常用缓存路径，未找到两个目标权重；未声称扫描所有磁盘。
- 找到既有英文 BGE ONNX 量化缓存，约 64.07 MiB；与目标中文 SentenceTransformer 及 Cross-Encoder 的语言、格式和用途不同，不直接替换。
- 项目、环境和日志在 D 盘；已有用户级 uv/npm/pip 缓存也在 D 盘，后续优先复用。阶段 1 的独立缓存保留，不迁移、合并或清空。离线脚本当前固定阶段 1 缓存路径，继续安装时可在 dot-source 之后设置进程级缓存路径；本轮未改启动脚本。
- 既有全套 pytest 162 passed / 0 failed/skipped，前端 3 tests passed/build PASS。本轮重新 GET 本地 health 成功；原始测试结果沿用事实卡，不冒充新跑的测试。

## LLM 配置兼容方案（未实施）

用户指定父目录 `.env` 为在线 LLM 的唯一配置来源。文件实际使用 `LLM_API_KEY / LLM_MODEL_ID / LLM_BASE_URL`；上游 `Settings` 默认读取当前工作目录 `.env`，只认 `DEEPSEEK_API_KEY / DEEPSEEK_MODEL / DEEPSEEK_BASE_URL`。即使直接指定父文件，也不会自动识别 `LLM_*`。配置文件仅脱敏读取，未修改或复制密钥。

先考虑在独立启动子进程映射这三个字段，避免改业务源码；当前只提出方案，未添加在线启动器、注入真实凭据或重启服务。离线脚本会主动清空 Key，未来在线启动不能误用该脚本覆盖映射。若需新增启动器或修改 settings/provider，先给出最小方案与验证方法，等待用户确认。

已用假密钥和 httpx.MockTransport 离线验证 `/v1/chat/completions` 拼接、JSON response_format 请求及 choices/usage 解析；退出 0，真实网络请求 0。该结果不证明实际第三方 endpoint 或配置 model ID 兼容。日志仅本地 `.local/logs/llm-compatibility-offline.log`。

## 费用与授权

1. 默认免费依赖和离线模式；本次真实外部模型请求数 0、API 费用 0。
2. 每次需要付费 API 前，先列出服务与模型、模型请求数（含重试）、Token 预算、服务实际单价与估算费用上限，等待明确授权。
3. 配置是第三方兼容服务，不能直接套用官方 DeepSeek 价目；目前未核定该服务计费，所以不发起在线验证。
4. 可在未来申请一次独立 generate 探针（1 请求、max_tokens=16、max_attempts=1）；这只是建议，尚未授权或执行。一次 chat 可能涉及多个模型请求。
5. 不自动购买额度、创建付费云资源或公网部署。下载模型或调整依赖前先报告兼容性、下载量和磁盘需求；需改代码时先提交方案。

此补充不启动阶段 2，不改变阶段 1 的离线口径或任何上游业务源码。
