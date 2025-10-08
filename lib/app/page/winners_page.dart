import 'package:flutter/material.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/swiper_banner.dart';
import 'package:flutter_app/core/models/ad_res.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/core/providers/winners_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WinnersPage extends ConsumerWidget {
  const WinnersPage({super.key});


  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final banners = ref.watch(winnersBannerProvider);

    Future<void> onRefresh() async {
      await Future.delayed(const Duration(milliseconds: 300));
    }


    return BaseScaffold(
      showBack: false,
      body: RefreshIndicator(
          child: ListView(
            children: [
              // banner
              banners.when(
                  data: (list) => _Banner(list: list),
                  error: (_,__)=> _Banner(list: []),
                  loading: ()=> _Banner(list: [])
              ),
              //total winners
              _TotalWinners(),
              //latest winners list
              _LatestWinnersList(),
              // tabs section
              _TabsSection(),
              // winners list
              _WinnerList(),
            ],
          ),
          onRefresh: ()=>onRefresh(),
      ),
    );
  }
}

/// Banner section
class _Banner extends StatelessWidget {
  final List<Banners>? list;
  const _Banner({required this.list});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
      child: SwiperBanner(banners: list??[]),
    );
  }
}

/// Total Winners section

class _TotalWinners extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text('Total Winners', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
          Text('12345', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),),
        ],
      ),
    );
  }
}

/// latest winners list section
class _LatestWinnersList extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Latest Winners', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
          const SizedBox(height: 8,),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text('U$index', style: const TextStyle(color: Colors.white),),
                ),
                title: Text('User $index'),
                subtitle: const Text('Won \$100'),
              );
            },
          )
        ],
      ),
    );
  }
}

/// Tabs section
class _TabsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
   return Container(
     padding: const EdgeInsets.all(16),
     child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         const Text('Winners by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
         const SizedBox(height: 8,),
         // Tabs
         DefaultTabController(
           length: 3,
           child: Column(
             children: [
               TabBar(
                 tabs: const [
                   Tab(text: 'Daily'),
                   Tab(text: 'Weekly'),
                   Tab(text: 'Monthly'),
                 ],
               ),
             ],
           ),
         )
       ],
     ),
   );
  }
}

/// Winners list section
class _WinnerList extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 20,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text('U$index', style: const TextStyle(color: Colors.white),),
            ),
            title: Text('User $index'),
            subtitle: const Text('Won \$100'),
          );
        },
      ),
    );
  }
}