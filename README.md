<div align="vertical-center">
  <a href="https://deepwiki.com/netease-kit/nim-uikit-flutter/1-overview">
    <img src="https://devin.ai/assets/deepwiki-badge.png" alt="Ask the Deepwiki" height="20"/>
  </a>
  <p>单击跳转查看 <a href="https://deepwiki.com/netease-kit/nim-uikit-flutter/1-overview">DeepWiki</a> 源码解读。</p>
</div>

-------------------------------

网易云信即时通讯界面组件（简称 IM UIKit）是基于 [NIM SDK（网易云信 IM SDK）](https://doc.yunxin.163.com/messaging2/concept/DI0Nzc2NzA?platform=client) 开发的一款即时通讯 UI 组件库，包括聊天、会话、圈组、搜索、通讯录、群管理等组件。通过 IM UIKit，您可快速集成包含 UI 界面的即时通讯应用。

## 适用客群

IM UIKit 简化了基于 NIM SDK 的应用开发过程，适合需要快速集成和定制即时通讯功能的开发者和企业客户。它不仅能助您快速实现 UI 功能，也支持调用 NIM SDK 相应的接口实现即时通讯业务逻辑和数据处理。因此，您在使用 IM UIKit 时仅需关注自身业务或个性化扩展。

<img alt="image.png" src="https://yx-web-nosdn.netease.im/common/ca3caa267f692e518d391f07e805aac9/image.png" style="width:65%;border: 0px solid #BFBFBF;">

## 主要功能

IM UIKit 主要分为会话、群组、联系人等几个 UI 子组件，每个 UI 组件负责展示不同的内容。更多详情，请参考 [功能概览](https://doc.yunxin.163.com/messaging-uikit/concept/zMzMDQ2MTg?platform=client) 和 [UI 组件介绍](https://doc.yunxin.163.com/messaging-uikit/concept/TI3NTgyNDA?platform=client)。

<img alt="image.png" src="https://yx-web-nosdn.netease.im/common/2deec52ef5a09b7f279844945613e8cc/image.png" style="width:65%;border: 0px solid #BFBFBF;">

## 功能优势

### 组件解耦

IM UIKit 不同组件可相互独立运行使用。您可按需选择组件，将其快速集成到您的应用，实现相应的 UI 功能，减少无用依赖。

### 简洁易用

IM UIKit 的业务逻辑层与 UI 层相互独立。在 UI 层，您仅需关注视图展示和事件处理。IM UIKit 清晰的数据流转处理，让 UI 层代码更简洁易懂。

### 自定义能力

IM UIKit 支持在各 UI 组件的初始化过程中配置自定义 UI。同时提供 Widget 和 View 的能力封装，助您快速将 UI 功能添加到您的应用中。

### 业务逻辑处理

IM UIKit 业务逻辑层提供完善的业务逻辑处理能力。您无需关心 SDK 层不同接口间的复杂处理逻辑，业务逻辑层一个接口帮您搞定所有。

## 工作原理

<style>
table th:first-of-type {
    width: 20%;
}
table th:nth-of-type(2) {
    width: 80%;
}
</style>

IM UIKit 采用 （Model–View–ViewModel）MVVM 架构模型，实现 UI 展示与业务逻辑开发的相互独立。

<img alt="app_structure_Flutter.png" src="https://yx-web-nosdn.netease.im/common/9570a86f7f95a5cbbca4508b012c222e/app_structure_Flutter.png" style="width:60%;border: 1px solid #BFBFBF;">

流程 | 说明
---- | ----
1 | IM UIKit 展示层的 Widget 向响应层的 ViewModel 发送请求。
2 | ViewModel 将请求经由业务逻辑层转发至 NIM SDK（网易云信 IM SDK）。
3 | NIM SDK 接收请求后触发回调，回调数据经由业务逻辑层发送至响应层处理，随后通知 Wiget 刷新。
4 | Widget 从响应层获取到新变更的数据，后根据新的数据重新构建 Widget 完成刷新。

## 组件架构

<img alt="app_structure_foure_Flutter.png" src="https://yx-web-nosdn.netease.im/common/15dda886b9c081fb46ce47cbe5930580/app_structure_foure_Flutter.png" style="width:60%;border: 1px solid #BFBFBF;">

上图中：

- UIKit UI 层的 `nim_contactkit_ui`、`nim_chatkit_ui` 和 `nim_conversationkit_ui`，对应上述工作原理图中的 Widget Tree。
- UIKit UI 层的 `nim_contactKit`、`nim_chatKit` 和 `nim_conversationKit`，对应上述工作原理图中的 Repository。
- UIKitCore 层对应上述工作原理图中的 Provider。

## 相关文档

- IM UIKit 的功能清单，请参考 [IM UIKit 功能概览](https://doc.yunxin.163.com/messaging-uikit/concept/zMzMDQ2MTg)。
- IM UIKit 的集成流程，请参考 [集成 IM UIKit](https://doc.yunxin.163.com/messaging-uikit/guide/DA2MzEzNTA?platform=flutter)。
