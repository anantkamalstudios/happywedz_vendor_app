// import 'package:flutter/material.dart';
// import 'package:happy_weds_vendors/utils/common_app_bar.dart';
//
// class PackageStoragePage extends StatefulWidget {
//   const PackageStoragePage({Key? key}) : super(key: key);
//
//   @override
//   State<PackageStoragePage> createState() => _PackageStoragePageState();
// }
//
// class _PackageStoragePageState extends State<PackageStoragePage> with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;
//
//   int? _selectedPackageIndex;
//   String _selectedUpgradePackage = '';
//   final TextEditingController _messageController = TextEditingController();
//
//   final List<Package> packages = [
//     Package(
//       name: 'Basic',
//       storage: '2 GB Storage',
//       price: '₹999',
//       priceSubtext: 'Per month, 30 days validity',
//       isPopular: false,
//       features: [
//         'Basic photo storage',
//         'Standard upload speed',
//         'Email support',
//       ],
//     ),
//     Package(
//       name: 'Standard',
//       storage: '5 GB Storage',
//       price: '₹1,999',
//       priceSubtext: 'Per month, 30 days validity',
//       isPopular: true,
//       features: [
//         'Enhanced photo storage',
//         'Priority upload speed',
//         'Chat & email support',
//         'Basic analytics',
//       ],
//     ),
//     Package(
//       name: 'Premium',
//       storage: '10 GB Storage',
//       price: '₹2,999',
//       priceSubtext: 'Per month, 30 days validity',
//       isPopular: false,
//       isPremium: true,
//       features: [
//         'Designed for professional photographers',
//         'Large storage for full wedding albums & videos',
//         'Premium experience with maximum flexibility',
//         'Priority 24/7 support',
//         'Advanced analytics & insights',
//       ],
//     ),
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
//     );
//
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.3),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
//
//     _animationController.forward();
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     _messageController.dispose();
//     super.dispose();
//   }
//
//   void _showUpgradeDialog() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => _buildUpgradeBottomSheet(),
//     );
//   }
//
//   Widget _buildUpgradeBottomSheet() {
//     return StatefulBuilder(
//       builder: (context, setModalState) {
//         return Container(
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
//           ),
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).viewInsets.bottom,
//           ),
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(24.0),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Center(
//                     child: Container(
//                       width: 48,
//                       height: 4,
//                       decoration: BoxDecoration(
//                         color: Colors.grey[300],
//                         borderRadius: BorderRadius.circular(2),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//                   const Text(
//                     'Request Package Upgrade',
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF1F2937),
//                       letterSpacing: -0.5,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Select a package and tell us why you need the upgrade',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                       height: 1.4,
//                     ),
//                   ),
//                   const SizedBox(height: 28),
//
//                   // Package selection
//                   const Text(
//                     'Select Package',
//                     style: TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w600,
//                       color: Color(0xFF374151),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   ...packages.map((pkg) {
//                     final isSelected = _selectedUpgradePackage == pkg.name;
//                     return Padding(
//                       padding: const EdgeInsets.only(bottom: 10),
//                       child: InkWell(
//                         onTap: () {
//                           setModalState(() {
//                             _selectedUpgradePackage = pkg.name;
//                           });
//                         },
//                         borderRadius: BorderRadius.circular(12),
//                         child: Container(
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: isSelected ? const Color(0xFF00509D).withOpacity(0.08) : Colors.grey[50],
//                             border: Border.all(
//                               color: isSelected ? const Color(0xFF00509D) : Colors.grey.shade200,
//                               width: isSelected ? 2 : 1,
//                             ),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Row(
//                             children: [
//                               Container(
//                                 width: 20,
//                                 height: 20,
//                                 decoration: BoxDecoration(
//                                   shape: BoxShape.circle,
//                                   border: Border.all(
//                                     color: isSelected ? const Color(0xFF00509D) : Colors.grey.shade400,
//                                     width: 2,
//                                   ),
//                                   color: isSelected ? const Color(0xFF00509D) : Colors.transparent,
//                                 ),
//                                 child: isSelected
//                                     ? const Icon(Icons.check, size: 14, color: Colors.white)
//                                     : null,
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       pkg.name,
//                                       style: TextStyle(
//                                         fontSize: 15,
//                                         fontWeight: FontWeight.w600,
//                                         color: isSelected ? const Color(0xFF00509D) : const Color(0xFF1F2937),
//                                       ),
//                                     ),
//                                     Text(
//                                       pkg.storage,
//                                       style: TextStyle(
//                                         fontSize: 12,
//                                         color: Colors.grey[600],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               Text(
//                                 pkg.price,
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: isSelected ? const Color(0xFF00509D) : const Color(0xFF1F2937),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   }).toList(),
//
//                   const SizedBox(height: 24),
//
//                   // Message to Admin
//                   const Text(
//                     'Message to Admin (Optional)',
//                     style: TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w600,
//                       color: Color(0xFF374151),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   TextField(
//                     controller: _messageController,
//                     maxLines: 4,
//                     decoration: InputDecoration(
//                       hintText: 'Tell us why you need this upgrade...',
//                       hintStyle: TextStyle(color: Colors.grey[400]),
//                       filled: true,
//                       fillColor: Colors.grey[50],
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(color: Colors.grey.shade200),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(color: Colors.grey.shade200),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: const BorderSide(color: Color(0xFF00509D), width: 2),
//                       ),
//                       contentPadding: const EdgeInsets.all(16),
//                     ),
//                   ),
//
//                   const SizedBox(height: 28),
//
//                   // Submit button
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: _selectedUpgradePackage.isEmpty
//                           ? null
//                           : () {
//                         // Handle submission
//                         Navigator.pop(context);
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: const Text('Upgrade request submitted successfully!'),
//                             backgroundColor: const Color(0xFF10B981),
//                             behavior: SnackBarBehavior.floating,
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                           ),
//                         );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF00509D),
//                         foregroundColor: Colors.white,
//                         disabledBackgroundColor: Colors.grey[300],
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 0,
//                       ),
//                       child: const Text(
//                         'Submit Request',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           letterSpacing: 0.2,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FA),
//       appBar: CommonAppBar(title: 'Packages & Storage'),
//       body: FadeTransition(
//         opacity: _fadeAnimation,
//         child: SlideTransition(
//           position: _slideAnimation,
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header Section
//                 Container(
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                       colors: [
//                         const Color(0xFF00509D),
//                         const Color(0xFF00509D).withOpacity(0.85),
//                       ],
//                     ),
//                   ),
//                   child: SafeArea(
//                     bottom: false,
//                     child: Padding(
//                       padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Choose Your Plan',
//                             style: TextStyle(
//                               fontSize: 28,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                               letterSpacing: -0.5,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             'Select the perfect storage plan for your photography business',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.white.withOpacity(0.9),
//                               height: 1.4,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 // Packages
//                 Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     children: List.generate(packages.length, (index) {
//                       return TweenAnimationBuilder<double>(
//                         duration: Duration(milliseconds: 400 + (index * 100)),
//                         tween: Tween(begin: 0.0, end: 1.0),
//                         curve: Curves.easeOutCubic,
//                         builder: (context, value, child) {
//                           return Transform.translate(
//                             offset: Offset(0, 20 * (1 - value)),
//                             child: Opacity(
//                               opacity: value,
//                               child: child,
//                             ),
//                           );
//                         },
//                         child: Padding(
//                           padding: const EdgeInsets.only(bottom: 16),
//                           child: _buildPackageCard(packages[index], index),
//                         ),
//                       );
//                     }),
//                   ),
//                 ),
//
//                 // Upgrade Request Section
//                 Container(
//                   margin: const EdgeInsets.fromLTRB(20, 8, 20, 32),
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.04),
//                         blurRadius: 20,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(10),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF00509D).withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: const Icon(
//                               Icons.upgrade,
//                               color: Color(0xFF00509D),
//                               size: 24,
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           const Expanded(
//                             child: Text(
//                               'Need More?',
//                               style: TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                                 color: Color(0xFF1F2937),
//                                 letterSpacing: -0.3,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 12),
//                       Text(
//                         'Request a package upgrade if you need more storage or features for your business',
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.grey[600],
//                           height: 1.5,
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton.icon(
//                           onPressed: _showUpgradeDialog,
//                           icon: const Icon(Icons.arrow_upward, size: 20),
//                           label: const Text(
//                             'Request Upgrade',
//                             style: TextStyle(
//                               fontSize: 15,
//                               fontWeight: FontWeight.w600,
//                               letterSpacing: 0.2,
//                             ),
//                           ),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF00509D),
//                             foregroundColor: Colors.white,
//                             padding: const EdgeInsets.symmetric(vertical: 14),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             elevation: 0,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPackageCard(Package package, int index) {
//     final isSelected = _selectedPackageIndex == index;
//     final bool isCurrentPlan = package.name == 'Premium'; // Example: Premium is current
//
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _selectedPackageIndex = index;
//         });
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: isSelected
//                 ? const Color(0xFF00509D)
//                 : package.isPopular
//                 ? const Color(0xFFEC4899)
//                 : Colors.transparent,
//             width: isSelected ? 2.5 : (package.isPopular ? 2 : 0),
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: isSelected
//                   ? const Color(0xFF00509D).withOpacity(0.15)
//                   : Colors.black.withOpacity(0.04),
//               blurRadius: isSelected ? 24 : 16,
//               offset: Offset(0, isSelected ? 8 : 4),
//             ),
//           ],
//         ),
//         child: Stack(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Package name and storage
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               package.name,
//                               style: const TextStyle(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                                 color: Color(0xFF1F2937),
//                                 letterSpacing: -0.5,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               package.storage,
//                               style: TextStyle(
//                                 fontSize: 13,
//                                 color: Colors.grey[600],
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       if (isCurrentPlan)
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFF10B981),
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: const Text(
//                             'Current Plan',
//                             style: TextStyle(
//                               fontSize: 11,
//                               fontWeight: FontWeight.w700,
//                               color: Colors.white,
//                               letterSpacing: 0.3,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//
//                   const SizedBox(height: 24),
//
//                   // Price
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Text(
//                         package.price,
//                         style: const TextStyle(
//                           fontSize: 36,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF00509D),
//                           letterSpacing: -1,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     package.priceSubtext,
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey[500],
//                     ),
//                   ),
//
//                   const SizedBox(height: 24),
//
//                   // Features
//                   ...package.features.map((feature) {
//                     return Padding(
//                       padding: const EdgeInsets.only(bottom: 12),
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Container(
//                             margin: const EdgeInsets.only(top: 2),
//                             padding: const EdgeInsets.all(3),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF10B981).withOpacity(0.15),
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(
//                               Icons.check,
//                               size: 14,
//                               color: Color(0xFF10B981),
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Text(
//                               feature,
//                               style: TextStyle(
//                                 fontSize: 13,
//                                 color: Colors.grey[700],
//                                 height: 1.4,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   }).toList(),
//
//                   const SizedBox(height: 24),
//
//                   // Select button
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: isCurrentPlan ? null : () {
//                         setState(() {
//                           _selectedPackageIndex = index;
//                         });
//                         // Handle package selection
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: isCurrentPlan
//                             ? Colors.grey[300]
//                             : (package.isPopular
//                             ? const Color(0xFFEC4899)
//                             : const Color(0xFF00509D)),
//                         foregroundColor: Colors.white,
//                         disabledBackgroundColor: Colors.grey[300],
//                         disabledForegroundColor: Colors.grey[600],
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 0,
//                       ),
//                       child: Text(
//                         isCurrentPlan
//                             ? 'Current Plan'
//                             : (package.isPopular ? 'Select Standard' : 'Select ${package.name}'),
//                         style: const TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                           letterSpacing: 0.2,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             // Popular badge
//             if (package.isPopular)
//               Positioned(
//                 top: 0,
//                 right: 0,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   decoration: const BoxDecoration(
//                     color: Color(0xFFEC4899),
//                     borderRadius: BorderRadius.only(
//                       topRight: Radius.circular(20),
//                       bottomLeft: Radius.circular(20),
//                     ),
//                   ),
//                   child: const Text(
//                     'Most Popular',
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                       letterSpacing: 0.5,
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class Package {
//   final String name;
//   final String storage;
//   final String price;
//   final String priceSubtext;
//   final bool isPopular;
//   final bool isPremium;
//   final List<String> features;
//
//   Package({
//     required this.name,
//     required this.storage,
//     required this.price,
//     required this.priceSubtext,
//     this.isPopular = false,
//     this.isPremium = false,
//     required this.features,
//   });
// }

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:happy_weds_vendors/utils/common_app_bar.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PackageStoragePage extends StatefulWidget {
  const PackageStoragePage({Key? key}) : super(key: key);

  @override
  State<PackageStoragePage> createState() => _PackageStoragePageState();
}

class _PackageStoragePageState extends State<PackageStoragePage> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 1;

  late Future<List<PackageModel>> _packagesFuture;
  List<PackageModel> packages = [];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
    _packagesFuture = fetchPackages();

  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  Future<List<PackageModel>> fetchPackages() async {
    final response = await http.get(
      Uri.parse('http://happywedz.com/api/admin/package'),
    );

    final body = jsonDecode(response.body);

    if (!body['success']) {
      throw Exception('Failed to load packages');
    }

    final List list = body['packages'];

    return list.map((e) {
      final apiPkg = PackageApiModel.fromJson(e);

      return PackageModel(
        name: apiPkg.name,
        storage: '${apiPkg.storageLimitGb} GB',
        price: apiPkg.price.toInt(),
        period: 'month',
        color: _getPackageColor(apiPkg.name),
        icon: _getPackageIcon(apiPkg.name),
        isPopular: apiPkg.name == 'Standard',
        isPremium: apiPkg.name == 'Premium',
        features: _buildFeatures(apiPkg),  id: apiPkg.id,

      );
    }).toList();
  }
  Color _getPackageColor(String name) {
    switch (name) {
      case 'Basic':
        return const Color(0xFF00509D);
      case 'Standard':
        return const Color(0xFF10B981);
      case 'Premium':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getPackageIcon(String name) {
    switch (name) {
      case 'Basic':
        return Icons.cloud_outlined;
      case 'Standard':
        return Icons.cloud_queue_outlined;
      case 'Premium':
        return Icons.cloud_done_outlined;
      default:
        return Icons.cloud;
    }
  }

  List<PackageFeature> _buildFeatures(PackageApiModel pkg) {
    return [
      PackageFeature('Storage up to ${pkg.storageLimitGb} GB', true),
      PackageFeature('Valid for ${pkg.durationDays} days', true),
      PackageFeature('Priority Support', pkg.name != 'Basic'),
      PackageFeature('Advanced analytics', pkg.name == 'Premium'),
      if (pkg.message != null)
        PackageFeature(pkg.message!.replaceAll('\n', ' • '), true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CommonAppBar(title: 'Packages & Storage'),
      // body: Column(
      //   children: [
      //     _buildHeader(),
      //     const SizedBox(height: 20),
      //     _buildPageIndicator(),
      //     const SizedBox(height: 24),
      //     _buildPackageCarousel(),
      //     const SizedBox(height: 24),
      //     _buildFeaturesList(),
      //     const Spacer(),
      //     _buildBottomActions(),
      //   ],
      // ),
      body: FutureBuilder<List<PackageModel>>(
        future: _packagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }

          packages = snapshot.data!;
          _currentPage = _currentPage.clamp(0, packages.length - 1);

          return Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildPageIndicator(),
              const SizedBox(height: 24),
              _buildPackageCarousel(),
              const SizedBox(height: 24),
              _buildFeaturesList(),
              const Spacer(),
              _buildBottomActions(),
            ],
          );
        },
      ),

    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Your',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: Color(0xFF1F2937),
              letterSpacing: -0.5,
            ),
          ),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                packages[_currentPage].color,
                packages[_currentPage].color.withOpacity(0.7),
              ],
            ).createShader(bounds),
            child: const Text(
              'Perfect Plan',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1.2,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Swipe to explore different storage options',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(packages.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: _currentPage == index ? 24 : 6,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? packages[_currentPage].color
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildPackageCarousel() {
    return SizedBox(
      height: 280,
      child: PageView.builder(
        controller: _pageController,
        itemCount: packages.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 1.0;
              if (_pageController.position.haveDimensions) {
                value = _pageController.page! - index;
                value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
              }
              return Center(
                child: SizedBox(
                  height: Curves.easeOut.transform(value) * 280,
                  child: child,
                ),
              );
            },
            child: _buildPackageCard(packages[index], index),
          );
        },
      ),
    );
  }

  Widget _buildPackageCard(PackageModel package, int index) {
    final isActive = _currentPage == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        children: [
          // Glow effect
          if (isActive)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: package.color.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ),

          // Main card
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  package.color,
                  package.color.withOpacity(0.8),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Pattern overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: CirclePatternPainter(
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              package.icon,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          if (package.isPopular)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '⭐ POPULAR',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: package.color,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        package.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${package.storage} Storage',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            '₹',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            package.price.toString(),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -2,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '/${package.period}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '30 days validity',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final package = packages[_currentPage];

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: package.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'What\'s Included',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: package.features.length,
                itemBuilder: (context, index) {
                  final feature = package.features[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: feature.included
                                ? package.color.withOpacity(0.15)
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            feature.included ? Icons.check : Icons.close,
                            size: 16,
                            color: feature.included
                                ? package.color
                                : Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature.title,
                            style: TextStyle(
                              fontSize: 14,
                              color: feature.included
                                  ? const Color(0xFF374151)
                                  : Colors.grey.shade400,
                              fontWeight: FontWeight.w500,
                              decoration: feature.included
                                  ? TextDecoration.none
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    final package = packages[_currentPage];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Select Plan button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showConfirmationSheet(package);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: package.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  shadowColor: package.color.withOpacity(0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Select ${package.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Request upgrade
            TextButton.icon(
              onPressed: _showUpgradeDialog,
              icon: const Icon(Icons.upload_outlined, size: 18),
              label: const Text('Need custom package?'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationSheet(PackageModel package) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: package.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                color: package.color,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Confirm ${package.name} Plan',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You\'re about to subscribe to the ${package.name} plan with ${package.storage} storage for ₹${package.price}/${package.period}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                       requestPackageUpgrade(
                      packageId: package.id, // 🔥 add id in PackageModel
                      message: 'Need ${package.name} plan',
                      package: package,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${package.name} plan activated! 🎉'),
                          backgroundColor: package.color,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: package.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
  Future<void> requestPackageUpgrade({
    required int packageId,
    required String message,
    required PackageModel package,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        _showInfoSnack('Session expired. Please login again.');
        return;
      }

      final response = await http.post(
        Uri.parse('https://happywedz.com/api/vendor/request-package-upgrade'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "package_id": packageId,
          "message": message,
        }),
      );

      final data = jsonDecode(response.body);

      print(response.statusCode);
      print(data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Request sent successfully 🎉'),
            backgroundColor: package.color,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (response.statusCode == 401) {
        _showInfoSnack('Invalid session. Please login again.');
      } else {
        _showInfoSnack(data['message'] ?? 'Something went wrong');
      }
    } catch (e) {
      _showErrorSnack('Network error. Please try again.');
      print(e);
    }
  }

  void _showInfoSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showUpgradeDialog() {
    final _messageController = TextEditingController();
    String? selectedPackage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Custom Package Request',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Need something different? Let us know!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    'Interested in',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: packages.map((pkg) {
                      final isSelected = selectedPackage == pkg.name;
                      return ChoiceChip(
                        label: Text(pkg.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            selectedPackage = selected ? pkg.name : null;
                          });
                        },
                        selectedColor: pkg.color,
                        backgroundColor: Colors.grey[100],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Tell us what you need',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'e.g., I need 20GB storage for multiple events...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF00509D),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),

                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedPackage == null ? null : () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Request sent! We\'ll contact you soon 📧'),
                            backgroundColor: Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00509D),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Send Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Custom painter for circle pattern
class CirclePatternPainter extends CustomPainter {
  final Color color;

  CirclePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const spacing = 30.0;
    const radius = 3.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Models
class PackageModel {
  final int id;

  final String name;
  final String storage;
  final int price;
  final String period;
  final Color color;
  final IconData icon;
  final bool isPopular;
  final bool isPremium;
  final List<PackageFeature> features;

  PackageModel({
    required this.name,
    required this.storage,
    required this.price,
    required this.period,
    required this.color,
    required this.icon,
    this.isPopular = false,
    this.isPremium = false,
    required this.features, required this.id,
  });
}
class PackageApiModel {
  final int id;
  final String name;
  final int storageLimitGb;
  final double price;
  final int durationDays;
  final String? message;

  PackageApiModel({
    required this.id,
    required this.name,
    required this.storageLimitGb,
    required this.price,
    required this.durationDays,
    this.message,
  });

  factory PackageApiModel.fromJson(Map<String, dynamic> json) {
    return PackageApiModel(
      id: json['id'],
      name: json['name'],
      storageLimitGb: json['storage_limit_gb'],
      price: double.parse(json['price']),
      durationDays: json['duration_days'],
      message: json['message'],
    );
  }
}

class PackageFeature {
  final String title;
  final bool included;

  PackageFeature(this.title, this.included);
}