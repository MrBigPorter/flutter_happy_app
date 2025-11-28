import 'package:flutter/material.dart';

class OrderDetailContent extends StatefulWidget {
  final String orderId;
  final List<String> imageList;
  final bool disableScroll;

  const OrderDetailContent({
    super.key,
    required this.orderId,
    required this.imageList,
    required this.disableScroll,
  });

  @override
  State<OrderDetailContent> createState() => _OrderDetailContentState();
}

class _OrderDetailContentState extends State<OrderDetailContent> {
  final ScrollController _scrollController = ScrollController();

  double _bannerOpacity = 1.0;
  double _headerOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    // 根据滚动距离控制 Banner 渐隐 & Header 渐显
    const double fadeStart = 80.0; // 开始渐隐的偏移
    const double fadeEnd   = 160.0; // 完全隐去/显现的偏移
    final double offset    = _scrollController.offset;

    double bannerOp, headerOp;
    if (offset <= fadeStart) {
      bannerOp = 1.0; headerOp = 0.0;
    } else if (offset >= fadeEnd) {
      bannerOp = 0.0; headerOp = 1.0;
    } else {
      final t = (offset - fadeStart) / (fadeEnd - fadeStart);
      bannerOp = 1.0 - t;
      headerOp = t;
    }

    if (bannerOp != _bannerOpacity || headerOp != _headerOpacity) {
      setState(() {
        _bannerOpacity = bannerOp;
        _headerOpacity = headerOp;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double bannerHeight = 350.0;
    const double overlap      = 24.0; // 白卡片往上覆盖的高度

    return Scaffold(
      body: Stack(
        children: [
          // 整个内容都放在一个滚动视图里
          SingleChildScrollView(
            controller: _scrollController,
            physics: widget.disableScroll
                ? const NeverScrollableScrollPhysics()
                : const ClampingScrollPhysics(),
            child: Column(
              children: [
                // 顶部 Banner，加 opacity 控制淡出
                Opacity(
                  opacity: _bannerOpacity,
                  child: SizedBox(
                    height: bannerHeight,
                    child: PageView.builder(
                      itemCount: widget.imageList.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          widget.imageList[index],
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ),

                // 主体内容，整体往上移动 overlap 像素来覆盖 Banner 底部
                Transform.translate(
                  offset: const Offset(0, -overlap),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: _buildBody(context), // 放订单信息列表
                  ),
                ),
              ],
            ),
          ),

          // 渐显 Header，透明度由 _headerOpacity 控制
          Opacity(
            opacity: _headerOpacity,
            child: _buildHeader(context),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            // 处理继续购买逻辑
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Continue Buying',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    return Container(
      height: kToolbarHeight + topPadding,
      padding: EdgeInsets.only(top: topPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              '₱3,000 Cash Prize', // 可以换成根据 orderId 获取的标题
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    // 根据订单实际信息自定义内容，这里示例：
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '₱3,000 Cash Prize',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          '1/800 sold',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        _buildInfoRow('Ticket Price', '10'),
        _buildInfoRow('Number of tickets', '1'),
        _buildInfoRow('Total Price', '10'),
        const Divider(),
        _buildInfoRow('Treasure Coins', '-10'),
        _buildInfoRow('Total Payment Amount', '0'),
        const Divider(),
        _buildInfoRow('Payment Method', 'Wallet'),
        _buildInfoRow('Order ID', 'ORD20251234'),
        _buildInfoRow('Payment Time', '2025-11-28 21:10:10'),
        const SizedBox(height: 80), // 留出底部按钮空间
        Text(
          '₱3,000 Cash Prize',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          '1/800 sold',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        _buildInfoRow('Ticket Price', '10'),
        _buildInfoRow('Number of tickets', '1'),
        _buildInfoRow('Total Price', '10'),
        const Divider(),
        _buildInfoRow('Treasure Coins', '-10'),
        _buildInfoRow('Total Payment Amount', '0'),
        const Divider(),
        _buildInfoRow('Payment Method', 'Wallet'),
        _buildInfoRow('Order ID', 'ORD20251234'),
        _buildInfoRow('Payment Time', '2025-11-28 21:10:10'),
        const SizedBox(height: 80), // 留出底部按钮空间
      ],
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

