import 'package:flutter/material.dart';

/// Responsive breakpoints for different screen sizes
class ResponsiveBreakpoints {
  // Private constructor to prevent instantiation
  ResponsiveBreakpoints._();
  
  // Breakpoint definitions (more aggressive mobile detection)
  static const double small = 800;  // Anything under 800px is mobile
  static const double medium = 1200; // 800-1200px is tablet
  static const double large = 1200;  // 1200px+ is desktop
  
  // Helper methods for screen size detection
  static bool isSmall(double width) => width < small;
  static bool isMedium(double width) => width >= small && width < large;
  static bool isLarge(double width) => width >= large;
  
  // Sidebar behavior breakpoints
  static bool shouldAutoCollapseSidebar(double width) => width < large;
  static bool shouldUseMobileSidebar(double width) => width < medium;
  
  // Get responsive sidebar width
  static double getSidebarWidth(double screenWidth, bool isExpanded) {
    if (screenWidth < large) {
      return 0; // Hidden on mobile and tablet, use drawer/AppBar instead
    } else {
      return isExpanded ? 260 : 80; // Expandable on large screens only
    }
  }
}

/// Helper widget for responsive layouts
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveInfo info) builder;
  
  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final info = ResponsiveInfo(
          screenWidth: constraints.maxWidth,
          screenHeight: constraints.maxHeight,
          isSmall: ResponsiveBreakpoints.isSmall(constraints.maxWidth),
          isMedium: ResponsiveBreakpoints.isMedium(constraints.maxWidth),
          isLarge: ResponsiveBreakpoints.isLarge(constraints.maxWidth),
        );
        
        return builder(context, info);
      },
    );
  }
}

/// Information about current responsive state
class ResponsiveInfo {
  final double screenWidth;
  final double screenHeight;
  final bool isSmall;
  final bool isMedium;
  final bool isLarge;
  
  const ResponsiveInfo({
    required this.screenWidth,
    required this.screenHeight,
    required this.isSmall,
    required this.isMedium,
    required this.isLarge,
  });
  
  /// Get responsive padding based on screen size
  EdgeInsets get padding {
    if (isSmall) {
      return const EdgeInsets.all(8);
    } else if (isMedium) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(24);
    }
  }
  
  /// Get responsive content padding (for text areas)
  EdgeInsets get contentPadding {
    if (isSmall) {
      return const EdgeInsets.all(12);
    } else if (isMedium) {
      return const EdgeInsets.all(20);
    } else {
      return const EdgeInsets.all(24);
    }
  }
  
  /// Get responsive horizontal margins for content areas
  EdgeInsets get horizontalMargins {
    if (isSmall) {
      return const EdgeInsets.symmetric(horizontal: 8);
    } else if (isMedium) {
      return const EdgeInsets.symmetric(horizontal: 16);
    } else {
      return const EdgeInsets.symmetric(horizontal: 24);
    }
  }
  
  /// Get responsive spacing between elements
  double get spacing {
    if (isSmall) {
      return 8;
    } else if (isMedium) {
      return 12;
    } else {
      return 16;
    }
  }
  
  /// Get responsive card padding
  EdgeInsets get cardPadding {
    if (isSmall) {
      return const EdgeInsets.all(12);
    } else if (isMedium) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(20);
    }
  }
}

/// Helper widget for adaptive spacing
class ResponsiveSpacing extends StatelessWidget {
  final double? small;
  final double? medium;
  final double? large;
  final bool isHorizontal;
  
  const ResponsiveSpacing({
    super.key,
    this.small,
    this.medium,
    this.large,
    this.isHorizontal = false,
  });
  
  const ResponsiveSpacing.horizontal({
    super.key,
    this.small,
    this.medium,
    this.large,
  }) : isHorizontal = true;
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, info) {
        double spacing;
        
        if (info.isSmall) {
          spacing = small ?? info.spacing;
        } else if (info.isMedium) {
          spacing = medium ?? info.spacing;
        } else {
          spacing = large ?? info.spacing;
        }
        
        return SizedBox(
          width: isHorizontal ? spacing : null,
          height: isHorizontal ? null : spacing,
        );
      },
    );
  }
}

/// Helper widget for responsive padding
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? small;
  final EdgeInsets? medium;
  final EdgeInsets? large;
  
  const ResponsivePadding({
    super.key,
    required this.child,
    this.small,
    this.medium,
    this.large,
  });
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, info) {
        EdgeInsets padding;
        
        if (info.isSmall) {
          padding = small ?? info.padding;
        } else if (info.isMedium) {
          padding = medium ?? info.padding;
        } else {
          padding = large ?? info.padding;
        }
        
        return Padding(
          padding: padding,
          child: child,
        );
      },
    );
  }
}

/// Extension on MediaQuery for responsive helpers
extension ResponsiveMediaQuery on MediaQueryData {
  bool get isSmall => ResponsiveBreakpoints.isSmall(size.width);
  bool get isMedium => ResponsiveBreakpoints.isMedium(size.width);
  bool get isLarge => ResponsiveBreakpoints.isLarge(size.width);
  
  ResponsiveInfo get responsive => ResponsiveInfo(
    screenWidth: size.width,
    screenHeight: size.height,
    isSmall: isSmall,
    isMedium: isMedium,
    isLarge: isLarge,
  );
}

/// Extension on TextTheme for responsive typography
extension ResponsiveTextTheme on TextTheme {
  /// Get responsive text size based on screen width
  TextStyle responsiveStyle(TextStyle baseStyle, double screenWidth) {
    if (ResponsiveBreakpoints.isSmall(screenWidth)) {
      return baseStyle.copyWith(fontSize: (baseStyle.fontSize ?? 14) * 0.9);
    } else if (ResponsiveBreakpoints.isMedium(screenWidth)) {
      return baseStyle.copyWith(fontSize: (baseStyle.fontSize ?? 14) * 0.95);
    } else {
      return baseStyle;
    }
  }
  
  /// Responsive headline for app title
  TextStyle responsiveHeadline(double screenWidth) {
    if (ResponsiveBreakpoints.isSmall(screenWidth)) {
      return titleMedium ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
    } else if (ResponsiveBreakpoints.isMedium(screenWidth)) {
      return titleLarge ?? const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
    } else {
      return headlineSmall ?? const TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
    }
  }
  
  /// Responsive body text for reading content
  TextStyle responsiveBodyText(double screenWidth) {
    const baseSize = 18.0; // Good size for reading ancient text
    
    if (ResponsiveBreakpoints.isSmall(screenWidth)) {
      return bodyMedium?.copyWith(fontSize: baseSize * 0.9) ?? 
             const TextStyle(fontSize: baseSize * 0.9);
    } else if (ResponsiveBreakpoints.isMedium(screenWidth)) {
      return bodyMedium?.copyWith(fontSize: baseSize * 0.95) ?? 
             const TextStyle(fontSize: baseSize * 0.95);
    } else {
      return bodyMedium?.copyWith(fontSize: baseSize) ?? 
             const TextStyle(fontSize: baseSize);
    }
  }
}

/// Responsive layout variants
enum LayoutType {
  mobile,
  tablet, 
  desktop,
}

/// Helper to determine layout type from screen width
LayoutType getLayoutType(double width) {
  if (ResponsiveBreakpoints.isSmall(width)) {
    return LayoutType.mobile;
  } else if (ResponsiveBreakpoints.isMedium(width)) {
    return LayoutType.tablet;
  } else {
    return LayoutType.desktop;
  }
}