import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';

final logger = Logger();

class SecondScreen extends StatefulWidget {
  const SecondScreen({super.key});

  @override
  State<SecondScreen> createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen>
    with SingleTickerProviderStateMixin {
  InAppWebViewController? _webViewController;
  late TabController _tabController;
  double progress = 0;
  int _currentLoadingTabIndex = -1; // -1 means no tab is loading

  @override
  void initState() {
    super.initState();
    _initializeTabController();
    _showWelcomeDialogAfterFirstFrame();

    // Add this line to listen for tab changes and update the state
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {}); // Update the state to switch the IndexedStack's child
      }
    });
  }

  void _initializeTabController() {
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _showWelcomeDialogAfterFirstFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialog(context);
    });
  }

  void _onTabChanged() {
    _updateLoadingStateOnTabSwitch(_tabController.index);
  }

  void _updateLoadingStateOnTabSwitch(int index) {
    setState(() {
      _currentLoadingTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.teal,
      title: _buildAppBarTitle(),
      actions: _buildAppBarActions(),
      bottom: _buildTabBar(),
    );
  }

  RichText _buildAppBarTitle() {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
          color: Colors.orangeAccent,
        ),
        children: <TextSpan>[
          TextSpan(text: 'Jobs'),
          TextSpan(
            text: ' & Gigs',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      IconButton(
        icon: const Icon(Icons.add_circle_outline_sharp,
            size: 30, color: Colors.white),
        onPressed: () => _openWebPage('https://kyeyo.info/submit-resume'),
        tooltip: 'Post a Job',
      ),
      IconButton(
        icon: const Icon(Icons.person_search_rounded,
            size: 30, color: Colors.white),
        onPressed: () => _openWebPage('https://kyeyo.info/resumes'),
        tooltip: 'Search Resumes',
      ),
      IconButton(
        icon: const Icon(Icons.bookmark, size: 26, color: Colors.white),
        onPressed: () => _openWebPage('https://kyeyo.info/my-bookmarks'),
        tooltip: 'Bookmarks',
      ),
      IconButton(
        icon: const Icon(Icons.support_agent_rounded,
            size: 26, color: Colors.white),
        onPressed: _launchWhatsApp,
        tooltip: 'Customer Support',
      ),
      IconButton(
        icon: const Icon(Icons.share, color: Colors.white),
        onPressed: _shareCurrentUrl,
        tooltip: 'Share',
      ),
    ];
  }

  TabBar _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: Colors.white,
      labelColor: Colors.orange,
      unselectedLabelColor: Colors.white,
      tabs: const [
        Tab(text: 'Home'),
        Tab(text: 'Job Alerts'),
        Tab(text: 'Candidate'),
        Tab(text: 'Employer'),
      ],
    );
  }

  Widget _buildBody() {
    return TabBarView(
      controller: _tabController,
      physics: const NeverScrollableScrollPhysics(), // Disable swipe to change tabs
      children: [
        _buildWebView('https://kyeyo.info/'),
        _buildWebView('https://kyeyo.info/job-alerts'),
        _buildWebView('https://kyeyo.info/candidate-dashboard'),
        _buildWebView('https://kyeyo.info/manage-jobs'),
      ],
    );
  }

  Widget _buildWebView(String url) {
    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(
            url: Uri.parse(url),
            headers: {
              'User-Agent':
              'Mozilla/5.0 (Linux; Android 10; Redmi Note 8 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.88 Mobile Safari/537.36'
            },
          ),
          initialOptions: InAppWebViewGroupOptions(
            android: AndroidInAppWebViewOptions(
              useHybridComposition: true,
              hardwareAcceleration: true,
            ),
            ios: IOSInAppWebViewOptions(
              allowsInlineMediaPlayback: true,
              allowsLinkPreview: true,
              allowsPictureInPictureMediaPlayback: true,
              isFraudulentWebsiteWarningEnabled: true,
              ignoresViewportScaleLimits: false,
              suppressesIncrementalRendering: false,
              allowsAirPlayForMediaPlayback: true,
            ),
            crossPlatform: InAppWebViewOptions(
              useOnDownloadStart: true,
              javaScriptEnabled: true,
              javaScriptCanOpenWindowsAutomatically: true,
              cacheEnabled: true,
              userAgent:
              'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.88 Mobile Safari/537.36',
            ),
          ),
          onProgressChanged: _onProgressChanged,
          onLoadStart: (controller, url) {
            _setLoadingState(url.toString());
          },
          onLoadStop: (controller, url) {
            _resetLoadingState();
            _clickLoginLink();
          },
          onWebViewCreated: (controller) {
            _webViewController = controller;
          },
        ),
        if (progress < 1.0)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 6, // Increase the thickness here
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white,
                color: Colors.orangeAccent,
              ),
            ),
          ),
        if (_currentLoadingTabIndex == 0)
          _buildShimmerEffect('assets/loading_homepage.png'),
        if (_currentLoadingTabIndex == 1)
          _buildShimmerEffect('assets/loading_jobalerts.png'),
        if (_currentLoadingTabIndex == 2)
          _buildShimmerEffect('assets/loading_candidates.png'),
        if (_currentLoadingTabIndex == 3)
          _buildShimmerEffect('assets/loading_employers.png'),
      ],
    );
  }

  Widget _buildShimmerEffect(String imagePath) {
    return Stack(
      children: [
        Container(
          color: Colors.white,
          child: Center(
            child: Image.asset(
              imagePath,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Shimmer.fromColors(
          baseColor: Colors.grey.withOpacity(0.1),
          highlightColor: Colors.white54.withOpacity(0.4),
          direction: ShimmerDirection.ttb,
          child: Container(
            color: Colors.white,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ],
    );
  }

  void _setLoadingState(String url) {
    setState(() {
      if (url == 'https://kyeyo.info/') {
        _currentLoadingTabIndex = 0; // Homepage
      } else if (url == 'https://kyeyo.info/job-alerts') {
        _currentLoadingTabIndex = 1; // Job Alerts
      } else if (url == 'https://kyeyo.info/candidate-dashboard') {
        _currentLoadingTabIndex = 2; // Candidate Dashboard
      } else if (url == 'https://kyeyo.info/manage-jobs') {
        _currentLoadingTabIndex = 3; // Manage Jobs
      } else {
        _currentLoadingTabIndex = -1; // No preloading image
      }
    });
  }

  void _resetLoadingState() {
    setState(() {
      _currentLoadingTabIndex = -1; // No tab is loading, so no preloading image
    });
  }

  FloatingActionButton _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _openUserMenu,
      tooltip: 'Menu',
      backgroundColor: Colors.teal,
      child: const Icon(Icons.menu, color: Colors.white),
    );
  }

  Future<bool> _onBackPressed() async {
    if (_webViewController != null && await _webViewController!.canGoBack()) {
      _webViewController!.goBack();
      return false;
    } else {
      return true;
    }
  }

  void _showWelcomeDialog(BuildContext context) {
    bool isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    // Define colors based on dark mode or light mode
    Color textColor = isDarkMode ? Colors.white : Colors.black;
    Color accentColor = isDarkMode ? Colors.purpleAccent : Colors.blue;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: SizedBox(
                width: 200, // Adjusted width
                height: 200, // Adjusted height
                child: Lottie.asset(
                  'assets/animation_job.json',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 5),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 20,
                  color: textColor,
                ),
                children: [
                  TextSpan(
                    text: 'Welcome to kyeyo.info!\n\n',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      fontSize: 25,
                    ),
                  ),
                  TextSpan(
                    text: 'Are you a freelancer or\n'
                        'job seeker? \n',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 25,
                    ),
                  ),
                  TextSpan(
                    text:
                    'Press (+) to post your CV so employers can find you.\n\n',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                  TextSpan(
                    text: 'Are you an employer or have a quick task to do?\n',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 25,
                    ),
                  ),
                  TextSpan(
                    text:
                    'Press the Employer tab \nto add Jobs or Quick Tasks.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _clickLoginLink(); // Call function to click the login link
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.purpleAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _clickLoginLink() async {
    // Evaluate JavaScript to click the login link
    if (_webViewController != null) {
      await _webViewController!.evaluateJavascript(source: '''
      document.querySelector('.login-btn').click();
    ''');
    } else {
      logger.e('WebViewController is not initialized');
    }
  }

  void _onProgressChanged(InAppWebViewController controller, int newProgress) {
    setState(() {
      progress = newProgress / 100;
    });
  }

  void _shareCurrentUrl() async {
    final currentUrl = await _webViewController?.getUrl();
    if (currentUrl != null) {
      Share.share(currentUrl.toString());
    }
  }

  void _openUserMenu() async {
    if (_webViewController != null) {
      await _webViewController!.evaluateJavascript(source: '''
          document.querySelector('.header-notifications-trigger a').click();
        ''');
    }
  }

  void _launchWhatsApp() async {
    const message = 'Hello Kyeyo Team';
    const number = '+256393100489';
    final url = 'https://wa.me/$number?text=${Uri.encodeComponent(message)}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      logger.e('Could not launch $url');
    }
  }

  void _openWebPage(String url) async {
    if (_webViewController != null) {
      _webViewController!.loadUrl(urlRequest: URLRequest(url: Uri.parse(url)));
    } else {
      logger.e('WebViewController is not initialized');
    }
  }
}
