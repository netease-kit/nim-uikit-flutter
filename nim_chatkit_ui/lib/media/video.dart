// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;
import 'package:netease_common_ui/extension.dart';
import 'package:nim_chatkit_ui/media/media_bottom_actions.dart';
import 'package:nim_core_v2/nim_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../chat_kit_client.dart';

/// media_kit 初始化管理器。
///
/// 在 UIKit 内部自动完成初始化，无需外部壳工程调用。
/// macOS 和 Windows 桌面端使用 media_kit（基于 libmpv / FFmpeg），
/// 支持几乎所有视频编码格式；移动端和 Web 端继续使用 video_player。
class MediaKitInitializer {
  static bool _initialized = false;

  /// 确保 media_kit 已初始化。可安全多次调用。
  static void ensureInitialized() {
    if (_initialized) return;
    if (kIsWeb) return;
    if (!Platform.isMacOS && !Platform.isWindows) return;
    mk.MediaKit.ensureInitialized();
    _initialized = true;
  }
}

/// 是否应该使用 media_kit 播放视频。
///
/// macOS 和 Windows 桌面端使用 media_kit，
/// 移动端（iOS/Android）和 Web 端使用 video_player。
bool get _useMediaKit {
  if (kIsWeb) return false;
  return Platform.isMacOS || Platform.isWindows;
}

class VideoViewer extends StatefulWidget {
  const VideoViewer({
    Key? key,
    required this.message,
    this.isDialog = false,
  }) : super(key: key);

  final NIMMessage message;

  /// 是否在 Dialog 中展示（桌面端/Web 端）
  final bool isDialog;

  @override
  State<StatefulWidget> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<VideoViewer> with WidgetsBindingObserver {
  // ---- video_player（移动端 / Web） ----
  VideoPlayerController? _controller;

  // ---- media_kit（macOS / Windows） ----
  mk.Player? _mkPlayer;
  mkv.VideoController? _mkController;

  bool _progressShow = true;
  Timer? _timer;
  bool _isPlaying = true;
  StreamSubscription? _phoneStateSub;

  // media_kit 流订阅
  final _mkSubscriptions = <StreamSubscription>[];

  // media_kit 播放状态
  Duration _mkPosition = Duration.zero;
  Duration _mkDuration = Duration.zero;
  bool _mkInitialized = false;

  late NIMMessageVideoAttachment attachment;

  void _playProgressAutoHide() {
    _timer?.cancel();
    if (_progressShow) {
      _timer = Timer(const Duration(seconds: 3), () {
        if (_progressShow) {
          setState(() {
            _progressShow = false;
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    attachment = widget.message.attachment as NIMMessageVideoAttachment;

    if (_useMediaKit) {
      MediaKitInitializer.ensureInitialized();
      _initMediaKit();
    } else {
      _initVideoPlayer();
    }
  }

  // ========================================================================
  // media_kit 初始化（macOS / Windows）
  // ========================================================================

  void _initMediaKit() {
    final localPath = attachment.path;
    final hasLocalFile = !kIsWeb &&
        localPath?.isNotEmpty == true &&
        File(localPath!).existsSync();

    String? mediaUri;
    if (hasLocalFile) {
      mediaUri = localPath;
    } else if (attachment.url?.isNotEmpty == true) {
      mediaUri = attachment.url;
    }

    if (mediaUri == null) return;

    _mkPlayer = mk.Player();
    _mkController = mkv.VideoController(_mkPlayer!);

    _mkSubscriptions.add(
      _mkPlayer!.stream.playing.listen((playing) {
        if (mounted) {
          _isPlaying = playing;
          setState(() {});
        }
      }),
    );

    _mkSubscriptions.add(
      _mkPlayer!.stream.completed.listen((completed) {
        if (completed && mounted) {
          _isPlaying = false;
          _mkPlayer!.seek(Duration.zero);
          setState(() {});
        }
      }),
    );

    _mkSubscriptions.add(
      _mkPlayer!.stream.position.listen((position) {
        if (mounted) {
          _mkPosition = position;
          setState(() {});
        }
      }),
    );

    _mkSubscriptions.add(
      _mkPlayer!.stream.duration.listen((duration) {
        if (mounted) {
          _mkDuration = duration;
          setState(() {});
        }
      }),
    );

    _mkSubscriptions.add(
      _mkPlayer!.stream.error.listen((error) {
        Alog.e(
          tag: 'ChatKit',
          moduleName: 'VideoViewer',
          content: 'media_kit player error: $error',
        );
        if (mounted) {
          _fallbackToSystemPlayer();
        }
      }),
    );

    // 构造 Media 并播放
    final media =
        hasLocalFile ? mk.Media('file://$mediaUri') : mk.Media(mediaUri!);

    _mkPlayer!.open(media).then((_) {
      if (mounted) {
        _mkInitialized = true;
        _isPlaying = true;
        setState(() {});
        _playProgressAutoHide();
      }
    }).catchError((error) {
      Alog.e(
        tag: 'ChatKit',
        moduleName: 'VideoViewer',
        content: 'media_kit open failed: $error',
      );
      if (mounted) {
        _fallbackToSystemPlayer();
      }
    });
  }

  // ========================================================================
  // video_player 初始化（移动端 / Web）
  // ========================================================================

  void _initVideoPlayer() {
    final localPath = attachment.path;
    final hasLocalFile = !kIsWeb &&
        localPath?.isNotEmpty == true &&
        File(localPath!).existsSync();

    if (hasLocalFile) {
      if (!kIsWeb && Platform.isAndroid) {
        _controller = VideoPlayerController.file(
          File(localPath!),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
          viewType: VideoViewType.platformView,
        );
      } else {
        _controller = VideoPlayerController.file(
          File(localPath!),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
        );
      }
    } else if (attachment.url?.isNotEmpty == true) {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(attachment.url!),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );
    } else {
      return;
    }

    _controller!.addListener(() {
      if (!_controller!.value.isInitialized) {
        return;
      }
      final value = _controller!.value;
      // 仅在视频已经有有效时长且播放到结尾时，才认为是播放结束
      if (!value.isPlaying &&
          value.duration > Duration.zero &&
          value.position >= value.duration) {
        _controller!.seekTo(Duration.zero);
        _isPlaying = false;
      } else {
        // 同步实际播放状态，避免中间播放按钮在播放时仍然显示
        _isPlaying = value.isPlaying;
      }
      if (mounted) setState(() {});
    });
    _controller!.setLooping(false);
    _isPlaying = true;

    _controller!.initialize().then((_) {
      if (mounted) {
        setState(() {});
        _controller!.play();
        _playProgressAutoHide();
      }
    }).catchError((error) {
      Alog.e(
        tag: 'ChatKit',
        moduleName: 'VideoViewer',
        content: 'Video player initialize failed: $error',
      );
      // 移动端没有 fallback（AVPlayer/ExoPlayer 支持绝大多数格式）
    });
  }

  // ========================================================================
  // Fallback 到系统播放器（桌面端最后兜底）
  // ========================================================================

  Future<void> _fallbackToSystemPlayer() async {
    final localPath = attachment.path;

    if (localPath?.isNotEmpty == true && File(localPath!).existsSync()) {
      await _launchLocalFile(localPath!);
    } else if (attachment.url?.isNotEmpty == true) {
      Alog.i(
        tag: 'ChatKit',
        moduleName: 'VideoViewer',
        content: 'Downloading video before fallback to system player',
      );
      final params = NIMDownloadMessageAttachmentParams(
        attachment: attachment,
        type: NIMDownloadAttachmentType.nimDownloadAttachmentTypeSource,
        thumbSize: NIMSize(
          width: attachment.width,
          height: attachment.height,
        ),
        messageClientId: widget.message.messageClientId,
      );
      final result =
          await NimCore.instance.storageService.downloadAttachment(params);
      if (result.isSuccess && result.data?.isNotEmpty == true) {
        final downloadedPath = result.data!;
        attachment.path = downloadedPath;
        await _launchLocalFile(downloadedPath);
      } else {
        Alog.e(
          tag: 'ChatKit',
          moduleName: 'VideoViewer',
          content:
              'Download video failed: ${result.code} ${result.errorDetails}, '
              'fallback to open URL directly',
        );
        final uri = Uri.tryParse(attachment.url!);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _launchLocalFile(String path) async {
    String filePath = path;

    final ext = attachment.ext?.toLowerCase();
    if (ext?.isNotEmpty == true && !path.toLowerCase().endsWith('.$ext')) {
      try {
        final newPath = '$path.$ext';
        final newFile = File(newPath);
        if (!newFile.existsSync()) {
          await File(path).copy(newPath);
        }
        filePath = newPath;
      } catch (e) {
        Alog.e(
          tag: 'ChatKit',
          moduleName: 'VideoViewer',
          content: 'Failed to copy file with extension: $e',
        );
      }
    }

    final uri = Uri.file(filePath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Alog.e(
        tag: 'ChatKit',
        moduleName: 'VideoViewer',
        content: 'Cannot launch local file uri: $uri',
      );
    }
  }

  // ========================================================================
  // 生命周期
  // ========================================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((AppLifecycleState.paused == state ||
            AppLifecycleState.inactive == state) &&
        _isPlaying) {
      _isPlaying = false;
      if (_useMediaKit) {
        _mkPlayer?.pause();
      } else {
        _controller?.pause();
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // 释放 video_player
    _controller?.dispose();

    // 释放 media_kit
    for (var sub in _mkSubscriptions) {
      sub.cancel();
    }
    _mkPlayer?.dispose();

    _timer?.cancel();
    _phoneStateSub?.cancel();
    _phoneStateSub = null;
    super.dispose();
  }

  // ========================================================================
  // UI 构建
  // ========================================================================

  Widget _buildContent() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Center(
          child: Hero(
            tag:
                '${widget.message.messageServerId}${widget.message.messageClientId}',
            child:
                _useMediaKit ? _buildMediaKitVideo() : _buildVideoPlayerVideo(),
          ),
        ),
        Visibility(
          visible: !_isPlaying,
          child: GestureDetector(
            onTap: _onPlayResume,
            child: Center(
              child: SvgPicture.asset(
                'images/ic_video_player.svg',
                package: kPackage,
                height: 80,
                width: 80,
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 75,
          child: Visibility(
            visible: _progressShow,
            child: _buildProgressBar(),
          ),
        ),
        MediaBottomActionOverlay(widget.message),
      ],
    );
  }

  Widget _buildMediaKitVideo() {
    if (!_mkInitialized || _mkController == null) {
      return Container();
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          _progressShow = !_progressShow;
          _playProgressAutoHide();
        });
      },
      child: mkv.Video(
        controller: _mkController!,
        controls: mkv.NoVideoControls,
      ),
    );
  }

  Widget _buildVideoPlayerVideo() {
    if (_controller?.value.isInitialized != true) {
      return Container();
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          _progressShow = !_progressShow;
          _playProgressAutoHide();
        });
      },
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      ),
    );
  }

  void _onPlayResume() {
    _isPlaying = true;
    if (_useMediaKit) {
      _mkPlayer?.play();
    } else {
      _controller?.play();
    }
  }

  void _onPlayPause() {
    if (_isPlaying) {
      _isPlaying = false;
      if (_useMediaKit) {
        _mkPlayer?.pause();
      } else {
        _controller?.pause();
      }
    } else {
      _isPlaying = true;
      if (_useMediaKit) {
        _mkPlayer?.play();
      } else {
        _controller?.play();
      }
    }
  }

  Widget _buildProgressBar() {
    final position = _useMediaKit
        ? _mkPosition
        : (_controller?.value.position ?? Duration.zero);
    final duration = _useMediaKit
        ? _mkDuration
        : (_controller?.value.duration ?? Duration.zero);
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Row(
      children: [
        GestureDetector(
          onTap: _onPlayPause,
          child: SvgPicture.asset(
            _isPlaying
                ? 'images/ic_video_pause.svg'
                : 'images/ic_video_resume.svg',
            package: kPackage,
            height: 26,
            width: 26,
          ),
        ),
        const SizedBox(width: 20),
        Text(
          position.inSeconds.formatTimeMMSS(),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 2,
            child: _useMediaKit
                ? LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    color: Colors.white,
                    backgroundColor: const Color(0x4d000000),
                  )
                : (_controller != null
                    ? VideoProgressIndicator(
                        _controller!,
                        colors: const VideoProgressColors(
                          playedColor: Colors.white,
                          backgroundColor: Color(0x4d000000),
                        ),
                        padding: EdgeInsets.zero,
                        allowScrubbing: false,
                      )
                    : const SizedBox.shrink()),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          duration.inSeconds.formatTimeMMSS(),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDialog) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.black,
          child: _buildContent(),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildContent(),
    );
  }
}
