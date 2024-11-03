/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';
import 'package:loftify/Utils/constant.dart';

class ImageGrid extends StatefulWidget {
  final Function(BuildContext, int, BorderRadius radius) itemBuilder;
  final int itemCount;
  final List<double> ratios;

  const ImageGrid({
    super.key,
    required this.itemBuilder,
    required this.itemCount,
    required this.ratios,
  });

  @override
  ImageGridState createState() => ImageGridState();
}

class ImageGridState extends State<ImageGrid>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late List<double> ratios;
  double calculatedAspectRatio = 1;
  double maxAspectRatio = 1.6;
  double minAspectRatio = 0.8;

  double get aspectRatio =>
      calculatedAspectRatio.clamp(minAspectRatio, maxAspectRatio);
  double radius = 12;

  BoxConstraints constraints = const BoxConstraints(
      maxHeight: maxMediaOrQuoteWidth, maxWidth: maxMediaOrQuoteWidth);

  @override
  void initState() {
    super.initState();
    ratios = widget.ratios;
    if (ratios.length != widget.itemCount) {
      ratios.addAll(
          List.generate(widget.itemCount - ratios.length, (index) => 1));
    }
    calculatedAspectRatio = ratios.fold<double>(0, (previousValue, element) {
      if (element == 0) {
        return previousValue;
      }
      return previousValue + element;
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    int count = widget.itemCount;
    Widget res;
    if (count == 0) {
      res = emptyWidget;
    } else if (count == 1) {
      res = _buildSingleImage(radius);
    } else if (count == 2) {
      res = _buildTwoImages(radius);
    } else if (count == 3) {
      res = _buildThreeImages(radius);
    } else if (count == 4) {
      res = _buildFourImages(radius);
    } else if (count == 5) {
      res = _buildFiveImages(radius);
    } else if (count == 6) {
      res = _buildSixImages(radius);
    } else if (count == 7) {
      res = _buildSevenImages(radius);
    } else if (count == 8) {
      res = _buildEightImages(radius);
    } else {
      res = _buildNineImages(radius);
    }
    return Container(constraints: constraints, child: res);
  }

  Widget _buildSingleImage(double radius) {
    return widget.itemBuilder(context, 0, BorderRadius.circular(radius));
  }

  Widget _buildTwoImages(double radius) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Row(
        children: [
          Expanded(
            child: widget.itemBuilder(
              context,
              0,
              BorderRadius.only(
                topLeft: Radius.circular(radius),
                bottomLeft: Radius.circular(radius),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: widget.itemBuilder(
              context,
              1,
              BorderRadius.only(
                topRight: Radius.circular(radius),
                bottomRight: Radius.circular(radius),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeImages(double radius) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Row(
        children: [
          Expanded(
            child: widget.itemBuilder(
                context,
                0,
                BorderRadius.only(
                    topLeft: Radius.circular(radius),
                    bottomLeft: Radius.circular(radius))),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: widget.itemBuilder(context, 1,
                      BorderRadius.only(topRight: Radius.circular(radius))),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: widget.itemBuilder(context, 2,
                      BorderRadius.only(bottomRight: Radius.circular(radius))),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFourImages(double radius) {
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemBuilder: (context, index) {
          var borderRadius = BorderRadius.zero;
          switch (index) {
            case 0:
              borderRadius =
                  BorderRadius.only(topLeft: Radius.circular(radius));
              break;
            case 1:
              borderRadius =
                  BorderRadius.only(topRight: Radius.circular(radius));
              break;
            case 2:
              borderRadius =
                  BorderRadius.only(bottomLeft: Radius.circular(radius));
              break;
            case 3:
              borderRadius =
                  BorderRadius.only(bottomRight: Radius.circular(radius));
              break;
          }
          return widget.itemBuilder(context, index, borderRadius);
        },
      ),
    );
  }

  Widget _buildFiveImages(double radius) {
    return AspectRatio(
      aspectRatio: 1,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: widget.itemBuilder(
                context,
                0,
                BorderRadius.only(
                    topLeft: Radius.circular(radius),
                    bottomLeft: Radius.circular(radius))),
          ),
          const SizedBox(width: 2),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                    child: Row(
                  children: [
                    Expanded(
                      child: widget.itemBuilder(context, 1, BorderRadius.zero),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                        child: widget.itemBuilder(
                            context,
                            2,
                            BorderRadius.only(
                                topRight: Radius.circular(radius)))),
                  ],
                )),
                const SizedBox(height: 2),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            widget.itemBuilder(context, 3, BorderRadius.zero),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                          child: widget.itemBuilder(
                              context,
                              4,
                              BorderRadius.only(
                                  bottomRight: Radius.circular(radius)))),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSixImages(double radius) {
    return AspectRatio(
      aspectRatio: 3 / 2,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemBuilder: (context, index) {
          var borderRadius = BorderRadius.zero;
          switch (index) {
            case 0:
              borderRadius =
                  BorderRadius.only(topLeft: Radius.circular(radius));
              break;
            case 2:
              borderRadius =
                  BorderRadius.only(topRight: Radius.circular(radius));
              break;
            case 3:
              borderRadius =
                  BorderRadius.only(bottomLeft: Radius.circular(radius));
              break;
            case 5:
              borderRadius =
                  BorderRadius.only(bottomRight: Radius.circular(radius));
              break;
          }
          return widget.itemBuilder(context, index, borderRadius);
        },
      ),
    );
  }

  Widget _buildSevenImages(double radius) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemBuilder: (context, index) {
              var borderRadius = BorderRadius.zero;
              switch (index) {
                case 0:
                  borderRadius =
                      BorderRadius.only(topLeft: Radius.circular(radius));
                  break;
                case 1:
                  borderRadius =
                      BorderRadius.only(topRight: Radius.circular(radius));
                  break;
              }
              return widget.itemBuilder(context, index, borderRadius);
            },
          ),
        ),
        const SizedBox(height: 2),
        AspectRatio(
          aspectRatio: 3,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemBuilder: (context, index) {
              var borderRadius = BorderRadius.zero;
              switch (index) {
                case 0:
                  borderRadius =
                      BorderRadius.only(bottomLeft: Radius.circular(radius));
                  break;
                case 2:
                  borderRadius =
                      BorderRadius.only(bottomRight: Radius.circular(radius));
                  break;
              }
              return widget.itemBuilder(context, index + 4, borderRadius);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEightImages(double radius) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 3 / 2,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemBuilder: (context, index) {
              var borderRadius = BorderRadius.zero;
              switch (index) {
                case 0:
                  borderRadius =
                      BorderRadius.only(topLeft: Radius.circular(radius));
                  break;
                case 2:
                  borderRadius =
                      BorderRadius.only(topRight: Radius.circular(radius));
                  break;
              }
              return widget.itemBuilder(context, index, borderRadius);
            },
          ),
        ),
        const SizedBox(height: 2),
        AspectRatio(
          aspectRatio: 2,
          child: Row(
            children: [
              Expanded(
                child: widget.itemBuilder(context, 6,
                    BorderRadius.only(bottomLeft: Radius.circular(radius))),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: widget.itemBuilder(context, 7,
                    BorderRadius.only(bottomRight: Radius.circular(radius))),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNineImages(double radius) {
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 9,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemBuilder: (context, index) {
          var borderRadius = BorderRadius.zero;
          switch (index) {
            case 0:
              borderRadius =
                  BorderRadius.only(topLeft: Radius.circular(radius));
              break;
            case 2:
              borderRadius =
                  BorderRadius.only(topRight: Radius.circular(radius));
              break;
            case 6:
              borderRadius =
                  BorderRadius.only(bottomLeft: Radius.circular(radius));
              break;
            case 8:
              borderRadius =
                  BorderRadius.only(bottomRight: Radius.circular(radius));
              break;
          }
          return widget.itemBuilder(context, index, borderRadius);
        },
      ),
    );
  }
}
