# TÀI LIỆU CHUYÊN SÂU 01: KIẾN TRÚC AVALANCHE & MẠNG FUJI C-CHAIN
**Nguồn tổng hợp:** Avalanche Official Developer Portal (build.avax.network), Ava Labs Documentation.

---

## 1. Kiến Trúc 3 Chuỗi (Primary Network) Của Avalanche
Khác với các blockchain đơn khối (Monolithic) như Bitcoin hay Ethereum, Avalanche xây dựng mạng lưới Primary Network gồm 3 chuỗi tương tác với nhau:

1. **X-Chain (Exchange Chain):**
   - Hoạt động dựa trên đồ thị DAG (Directed Acyclic Graph) và cơ chế đồng thuận Avalanche Consensus.
   - Nhiệm vụ: Tạo lập, quản lý và giao dịch các tài sản kỹ thuật số (AVAX native và các token tùy biến).
2. **P-Chain (Platform Chain):**
   - Hoạt động dựa trên cơ chế đồng thuận Snowman Consensus.
   - Nhiệm vụ: Điều phối các validator, theo dõi trạng thái các subnet, và cho phép tạo mới các mạng L1 tùy biến (Custom Subnets).
3. **C-Chain (Contract Chain) — Trọng Tâm Lập Trình DApp:**
   - Hoạt động như một máy ảo Ethereum (EVM) hoàn chỉnh, tương thích 100% với các công cụ Ethereum (Solidity, Foundry, Hardhat, Remix, Viem, Wagmi).
   - Được vận hành bởi **Snowman Consensus** (thuật toán BFT tối ưu hóa tuyến tính).

---

## 2. Vì Sao Avalanche C-Chain Vượt Trội?
- **Thời Gian Xác Thực Khối Dưới 1 Giây (Sub-second Finality):** Không cần chờ 12-15 giây như Ethereum hay phải đợi nhiều block xác nhận (Probabilistic Finality). Trên Avalanche, một khi giao dịch đã vào block thì được coi là bất biến (Deterministic Finality).
- **Phí Gas Siêu Rẻ & Ổn Định:** Sử dụng thuật toán Dynamic Fee (tương thích EIP-1559), giúp phí giao dịch chỉ dao động từ vài cent (USD).
- **Khả Năng Mở Rộng Qua Subnet (App-chain):** Cho phép các dự án tách riêng một subnet độc lập nhưng vẫn thừa hưởng bảo mật của Avalanche.

---

## 3. Thông Số Kỹ Thuật Avalanche Fuji Testnet (Bắt Buộc Nhớ)
Khi phát triển và triển khai Smart Contract lên mạng thử nghiệm Fuji:

| Thuộc tính | Giá trị chính thức |
| :--- | :--- |
| **Network Name** | Avalanche Fuji Testnet |
| **Chain ID** | `43113` (Hex: `0xa869`) |
| **Currency Symbol** | AVAX (Fuji testnet) |
| **RPC Endpoint (HTTP)** | `https://api.avax-test.network/ext/bc/C/rpc` |
| **WebSocket Endpoint** | `wss://api.avax-test.network/ext/bc/C/ws` |
| **Block Explorer** | [Snowscan Fuji](https://testnet.snowscan.xyz/) / [Snowtrace Testnet](https://testnet.snowtrace.io/) |
| **Official Faucet** | [faucet.avax.network](https://faucet.avax.network/) |

---

## 4. Điểm Khác Biệt Quan Trọng Cần Lưu Ý Cho Lập Trình Viên:
- **Node Avalanche Không Lưu Private Key Unencrypted:** Trên các node Geth truyền thống, lập trình viên có thể mở khóa tài khoản bằng `personal_unlockAccount`. Trên Avalanche, các phương thức `eth_sendTransaction` và `eth_sign` sẽ bị từ chối nếu không được ký ngoài (External Signing) bằng private key trước khi gửi qua `eth_sendRawTransaction`.
- **EVM Version:** Avalanche Fuji hiện hỗ trợ EVM version `cancun` hoặc `shanghai`. Khi biên dịch bằng `solc`, cần chỉ định evmVersion phù hợp.
