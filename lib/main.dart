import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(AdRewardIRApp());
}

class AdRewardIRApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AdReward IR',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        accentColor: Colors.orange,
        fontFamily: 'Vazir',
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tokenBalance = 0;
  int _screenTimeSeconds = 0;
  bool _screenTimeWarning = false;
  Timer? _screenTimer;
  List<Map<String, dynamic>> _ads = [
    {
      'id': 1,
      'title': 'قهوه رایگان از کافه لمیز',
      'reward': 500,
      'image': 'coffee',
      'isHot': true,
    },
    {
      'id': 2,
      'title': 'گوشی سامسونگ ۲۰% تخفیف',
      'reward': 1000,
      'image': 'phone',
      'isHot': false,
    },
    {
      'id': 3,
      'title': 'دوره آموزشی رایگان',
      'reward': 750,
      'image': 'course',
      'isHot': true,
    },
  ];
  List<Map<String, dynamic>> _leaderboard = [
    {'name': 'زهرا احمدی', 'tokens': 1250, 'rank': 1},
    {'name': 'علی رضایی', 'tokens': 1000, 'rank': 2},
    {'name': 'مریم محمدی', 'tokens': 800, 'rank': 3},
  ];
  List<String> _history = [];
  int _totalViews = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startScreenTimeTracker();
  }

  _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _tokenBalance = prefs.getInt('tokenBalance') ?? 0;
      _history = prefs.getStringList('history') ?? [];
      _totalViews = prefs.getInt('totalViews') ?? 0;
    });
  }

  _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('tokenBalance', _tokenBalance);
    prefs.setStringList('history', _history);
    prefs.setInt('totalViews', _totalViews);
  }

  _startScreenTimeTracker() {
    _screenTimer = Timer.periodic(Duration(seconds: 10), (timer) { // هر 10 ثانیه برای تست
      setState(() {
        _screenTimeSeconds += 10;
        if (_screenTimeSeconds >= 60) { // 60 ثانیه برای تست (4 ساعت واقعی: 14400)
          _screenTimeWarning = true;
        }
      });
    });
  }

  int _calculateTieredReward(int baseReward, int viewRank) {
    if (viewRank > 1000) return (baseReward * 0.1).round(); // حداقل پاداش
    double multiplier = 10.0 / pow(viewRank, 0.8); // فرمول پلکانی
    return (baseReward * (multiplier / 10)).round().clamp(100, baseReward * 2);
  }

  _watchAd(Map<String, dynamic> ad) {
    setState(() {
      _totalViews++;
      int rank = _totalViews;
      int reward = _calculateTieredReward(ad['reward'], rank);
      _tokenBalance += reward;
      _history.insert(0, 'تبلیغ "${ad['title']}" (#$rank): +$reward ADR Coin');
      if (_history.length > 50) _history.removeLast();
      
      // آپدیت leaderboard
      _leaderboard.add({
        'name': 'شما',
        'tokens': _tokenBalance,
        'rank': _leaderboard.length + 1
      });
      _leaderboard.sort((a, b) => b['tokens'].compareTo(a['tokens']));
      if (_leaderboard.length > 10) _leaderboard.removeLast();
    });
    _saveData();
    _showRewardDialog(reward, ad['title'], rank);
  }

  _shareAd(Map<String, dynamic> ad) {
    setState(() {
      int shareReward = (ad['reward'] * 0.2).round(); // 20% پاداش share
      _tokenBalance += shareReward;
      _history.insert(0, 'شیر تبلیغ "${ad['title']}": +$shareReward ADR Coin');
    });
    _saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('لینک شیر شد! +$shareReward ADR Coin', 
                     style: TextStyle(fontFamily: 'Vazir')),
        backgroundColor: Colors.green,
      ),
    );
  }

  _showRewardDialog(int reward, String adTitle, int rank) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تبریک!', style: TextStyle(fontFamily: 'Vazir')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('+$reward ADR Coin', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
            Text('رتبه شما: $rank از ۱۰۰۰', style: TextStyle(fontFamily: 'Vazir')),
            Text('تبلیغ: $adTitle', style: TextStyle(fontFamily: 'Vazir')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('بستن', style: TextStyle(fontFamily: 'Vazir')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AdReward IR', style: TextStyle(fontFamily: 'Vazir')),
        backgroundColor: Colors.blue[800],
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () {},
              ),
              if (_ads.where((ad) => ad['isHot']).length > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${_ads.where((ad) => ad['isHot']).length}',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _screenTimeWarning 
        ? _buildScreenTimeWarning()
        : RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _ads.shuffle();
              });
            },
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance Card
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[600]!, Colors.blue[400]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text('موجودی شما', style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Vazir')),
                        SizedBox(height: 8),
                        Text('$_tokenBalance ADR Coin', 
                             style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('رتبه: ${_leaderboard.indexWhere((u) => u['name'] == 'شما') + 1 ?? '---'}', 
                             style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  
                  // Hot Ads Section
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('🔥 تبلیغ‌های داغ', 
                               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Vazir')),
                  ),
                  ..._ads.where((ad) => ad['isHot']).map((ad) => _buildAdCard(ad)).toList(),
                  
                  // All Ads Section
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('📺 همه تبلیغات', 
                               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Vazir')),
                  ),
                  ..._ads.where((ad) => !ad['isHot']).map((ad) => _buildAdCard(ad)).toList(),
                  
                  // Leaderboard
                  SizedBox(height: 16),
                  Container(
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🏆 برترین‌ها', 
                             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Vazir')),
                        SizedBox(height: 12),
                        ..._leaderboard.take(3).map((user) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: user['rank'] == 1 ? Colors.amber : 
                                               user['rank'] == 2 ? Colors.grey[400] : Colors.brown,
                                child: Text('${user['rank']}'),
                              ),
                              SizedBox(width: 12),
                              Expanded(child: Text(user['name'], style: TextStyle(fontFamily: 'Vazir'))),
                              Text('${user['tokens']} ADR', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  
                  // Transparency Dashboard
                  Container(
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📊 شفافیت', 
                             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Vazir')),
                        SizedBox(height: 8),
                        Text('💰 بودجه کل: ۳,۰۰۰,۰۰۰ تومان', style: TextStyle(fontFamily: 'Vazir')),
                        Text('👥 هدف: ۱,۰۰۰ بازدید', style: TextStyle(fontFamily: 'Vazir')),
                        Text('🎯 بازدید شده: $_totalViews', style: TextStyle(fontFamily: 'Vazir')),
                        Text('💎 توکن‌های شما: $_tokenBalance', style: TextStyle(fontFamily: 'Vazir', fontWeight: FontWeight.bold)),
                        Text('📈 تبدیل: بعد از ۱M کاربر', style: TextStyle(fontFamily: 'Vazir', color: Colors.green[700]!)),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 80), // برای bottom nav
                ],
              ),
            ),
          ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'خانه'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'کیف پول'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'رتبه'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'پروفایل'),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => 
              WalletScreen(_tokenBalance, _history)));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => 
              LeaderboardScreen(_leaderboard)));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('کد ریفرال: ADR${Random().nextInt(1000)}', 
                                 style: TextStyle(fontFamily: 'Vazir'))),
          );
        },
        child: Icon(Icons.share),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 4,
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: ad['isHot'] ? Colors.orange : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            ad['image'] == 'coffee' ? Icons.local_cafe :
            ad['image'] == 'phone' ? Icons.phone_android :
            Icons.school,
            color: Colors.white,
            size: 30,
          ),
        ),
        title: Text(ad['title'], style: TextStyle(fontFamily: 'Vazir', fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Icon(Icons.star, color: Colors.orange, size: 16),
            SizedBox(width: 4),
            Text('${ad['reward']} ADR Coin', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            if (ad['isHot']) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('HOT', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.play_arrow, color: Colors.green),
              onPressed: () => _watchAd(ad),
              tooltip: 'مشاهده تبلیغ',
            ),
            IconButton(
              icon: Icon(Icons.share, color: Colors.blue),
              onPressed: () => _shareAd(ad),
              tooltip: 'اشتراک‌گذاری',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenTimeWarning() {
    return Center(
      child: Card(
        elevation: 8,
        margin: EdgeInsets.all(32),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text('⏰ زمان استفاده', 
                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Vazir')),
              SizedBox(height: 8),
              Text('بیش از حد استاندارد استفاده کردی!', style: TextStyle(fontFamily: 'Vazir')),
              Text('به چشمانت استراحت بده 😊', style: TextStyle(fontFamily: 'Vazir')),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _screenTimeWarning = false);
                    },
                    icon: Icon(Icons.play_arrow),
                    label: Text('ادامه', style: TextStyle(fontFamily: 'Vazir')),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _screenTimer?.cancel(),
                    icon: Icon(Icons.pause),
                    label: Text('استراحت', style: TextStyle(fontFamily: 'Vazir')),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _screenTimer?.cancel();
    super.dispose();
  }
}

// صفحات دیگر (Wallet, Leaderboard)
class WalletScreen extends StatelessWidget {
  final int tokenBalance;
  final List<String> history;
  
  WalletScreen(this.tokenBalance, this.history);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('کیف پول', style: TextStyle(fontFamily: 'Vazir'))),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.purple[600]!, Colors.purple[400]!]),
            ),
            child: Column(
              children: [
                Text('موجودی کل', style: TextStyle(color: Colors.white, fontSize: 18)),
                Text('$tokenBalance ADR Coin', 
                     style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) => Card(
                child: ListTile(
                  title: Text(history[index], style: TextStyle(fontFamily: 'Vazir')),
                  leading: Icon(Icons.receipt, color: Colors.green),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LeaderboardScreen extends StatelessWidget {
  final List<Map<String, dynamic>> leaderboard;
  
  LeaderboardScreen(this.leaderboard);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🏆 جدول رده‌بندی', style: TextStyle(fontFamily: 'Vazir'))),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: leaderboard.length,
        itemBuilder: (context, index) {
          var user = leaderboard[index];
          Color bgColor = index == 0 ? Colors.amber : 
                         index == 1 ? Colors.grey[300]! : 
                         index == 2 ? Colors.brown[100]! : Colors.white;
          return Card(
            color: bgColor,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: index == 0 ? Colors.amber : 
                               index == 1 ? Colors.grey : Colors.brown,
                child: Text('${index + 1}'),
              ),
              title: Text(user['name'], style: TextStyle(fontFamily: 'Vazir', fontWeight: FontWeight.bold)),
              trailing: Text('${user['tokens']} ADR', 
                             style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ),
          );
        },
      ),
    );
  }
}
