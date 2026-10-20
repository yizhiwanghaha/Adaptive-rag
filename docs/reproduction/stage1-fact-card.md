# Adaptive-RAG 工程事实卡

- **阶段与任务**：阶段 1，Windows 离线复现与 Baseline；2026-10-20（Asia/Shanghai）。本阶段完成后暂停。
- **来源与版本**：[上游](https://github.com/JEen-wang/Adaptive-rag) → [个人 Fork](https://github.com/yizhiwanghaha/Adaptive-rag)，MIT 保留；基线 commit `a1317f20dde5f81e3d2a28bc6f98ddb9b445546d`，工作分支 `repro/stage1-baseline`。本次新增提交仅为复现材料。
- **本地目录**：`D:\AI-Agent-Learning\03_项目\Adaptive-RAG`；独立 `.venv`，Python 3.12.9；FastAPI 0.115.14、LangGraph 0.2.76、langchain-core 0.3.86、Pydantic 2.14.0、SQLAlchemy 2.0.54、pytest 8.4.2。Node 24.12.0 / npm 11.6.2。
- **可重放命令与退出码**：`uv sync --locked --extra dev --python D:\miniconda\python.exe`、`uv lock --check`、`python -m pytest -q`（附 JUnit 输出）、`python -m eval.runner --task retrieval`、Ruff format/lint、mypy、compileall、`npm ci` / `npm test` / `npm run build` 均为 **0**；[完整命令与原始证据位置](stage1-evidence.md)。
- **运行配置**：执行 `scripts/repro/offline-env.ps1`；无真实模型 Key，禁用本地模型及 Unstructured，SQLite `data/local/stage1.db`，内存向量库、无 Redis/Qdrant/远程 MCP；未 seed 演示订单。API 仅绑定 `127.0.0.1:8000`。
- **入口验收**：API **PASS**（health/ready/chat 实际 HTTP 200）；CLI **PASS**（输入“你好”后退出）；Web 构建、测试、HTML/JS/CSS HTTP **PASS**，浏览器视觉/交互 **NOT RUN**（检查工具页面崩溃）。
- **路径验收**：DIRECT / SINGLE / MULTI / REFUSE **PASS，均为离线真实 HTTP 路径**；SINGLE/MULTI 有引用。AGENT 路由已命中，但成功订单查询、确认/执行 **NOT RUN**；缺失订单返回无关 `gift_card` 片段，记为业务负例 **FAIL**，不计成功。
- **模型口径**：实际 `OfflineLLMProvider`、`HashEmbeddingProvider`、lexical Rerank；未安装 torch/sentence-transformers，未下载模型；在线 LLM、本地 BGE 与 Cross-Encoder、LLM 多跳推理/自纠错质量 **NOT RUN**。响应模型 Token 为 0，不是生成式 LLM 端到端通过。
- **测试 / Evaluation**：最小测试 **14 passed / 0 failed / 0 skipped，7.79s**；全套 **162 passed / 0 failed / 0 skipped，9.71s**（1 条 LangChain 弃用警告；命令墙钟 22.59s）；前端 **3 passed / 0 failed，2 个文件**。检索集 `eval/dataset/rag_eval.jsonl` 65 条：BM25 P@1 **0.8000** / R@3 **0.9000**；Hash 混合 RRF **0.7077 / 0.8231**；lexical fallback **0.8000 / 0.9000**。这是本次降级结果，不代表 BGE 或作者历史指标。
- **关键源码 / 下阶段三个入口**：`app/asgi.py:5` → `create_app`；`app/services/chat_service.py:70` → `ChatService.chat`；`app/agents/graph.py:45` → `build_graph`（均按本地基线核对）。
- **改动与 Git**：初始 `git status --short` 为空；新增 `scripts/repro/` 和 `docs/reproduction/`，业务源码/依赖锁/许可证无改动。日志、数据库、环境、模型缓存、原始 Evaluation JSON 只留本地，不提交；父仓库已有修改保持原样。
- **错误 / 限制**：首次 HTTP 在启动就绪前连接被拒，检查日志后成功重试；未改源码。`/ready` 实测离线 Provider 仍返回 `llm.ready=true, detail=configured`，不能作为真实模型可用证据。Web 视觉未验；订单成功链路、云端 CI、覆盖率门槛未验。
- **学习窗口可追问**：① 为什么 health/ready 成功不能说明真实 LLM 可用？② SINGLE/MULTI 的路径通过与答案质量通过有什么区别？③ 缺失订单为什么不能按 `strategy=agent` 判为业务成功？
- **下一阶段建议（待用户同意）**：阶段 2，围绕一条政策问题和一条只读模拟订单查询收集调用链证据；先确认是否允许向专用模拟数据库写入种子数据。本次不自动进入。
