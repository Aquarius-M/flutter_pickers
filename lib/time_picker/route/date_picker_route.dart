import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pickers/time_picker/model/date_item_model.dart';
import 'package:flutter_pickers/time_picker/model/date_mode.dart';
import 'package:flutter_pickers/time_picker/model/date_time_data.dart';
import 'package:flutter_pickers/time_picker/model/date_type.dart';
import 'package:flutter_pickers/time_picker/model/pduration.dart';
import 'package:flutter_pickers/time_picker/model/suffix.dart';

import '../time_utils.dart';

typedef DateCallback(PDuration res);

const double _pickerHeight = 220.0;
const double _pickerTitleHeight = 44.0;
const double _pickerItemHeight = 40.0;
double _pickerMenuHeight = 36.0;

class DatePickerRoute<T> extends PopupRoute<T> {
  DatePickerRoute({
    this.mode,
    this.initDate,
    this.maxDate,
    this.minDate,
    this.suffix,
    this.menu,
    this.menuHeight,
    this.cancelWidget,
    this.commitWidget,
    this.headDecoration,
    this.title,
    this.backgroundColor,
    this.textColor,
    this.showTitleBar,
    this.onChanged,
    this.onConfirm,
    this.theme,
    this.barrierLabel,
    RouteSettings settings,
  }) : super(settings: settings) {
    if (menuHeight != null) _pickerMenuHeight = menuHeight;
  }

  final DateMode mode;
  final PDuration initDate;
  final PDuration maxDate;
  final PDuration minDate;
  final Suffix suffix;

  final bool showTitleBar;
  final DateCallback onChanged;
  final DateCallback onConfirm;
  final ThemeData theme;
  final Color backgroundColor; // 背景色
  final Color textColor; // 文字颜色
  final Widget title;
  final Widget menu;
  final double menuHeight;
  final Widget cancelWidget;
  final Widget commitWidget;
  final Decoration headDecoration; // 头部样式

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  bool get barrierDismissible => true;

  @override
  final String barrierLabel;

  @override
  Color get barrierColor => Colors.black54;

  AnimationController _animationController;

  @override
  AnimationController createAnimationController() {
    assert(_animationController == null);
    _animationController = BottomSheet.createAnimationController(navigator.overlay);
    return _animationController;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    Widget bottomSheet = MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: _PickerContentView(
        mode: mode,
        initData: initDate,
        route: this,
      ),
    );
    if (theme != null) {
      bottomSheet = Theme(data: theme, child: bottomSheet);
    }

    return bottomSheet;
  }
}

class _PickerContentView extends StatefulWidget {
  _PickerContentView({
    Key key,
    this.mode,
    this.initData,
    @required this.route,
  }) : super(key: key);

  final DateMode mode;
  final PDuration initData;
  final DatePickerRoute route;

  @override
  State<StatefulWidget> createState() => _PickerState(this.mode, this.initData);
}

class _PickerState extends State<_PickerContentView> {
  // 是否显示 [年月日时分秒]
  DateItemModel dateItemModel;

  // 初始 设置选中的数据
  final PDuration _initData;

  // 选中的数据  用于回传
  PDuration _selectData;

  // 所有item 对应的数据
  DateTimeData _dateTimeData;

  Animation<double> animation;
  Map<DateType, FixedExtentScrollController> scrollCtrl = {};

  _PickerState(DateMode mode, this._initData) {
    this.dateItemModel = DateItemModel.parse(mode);
    _init();
  }

  _init() {
    scrollCtrl.clear();

    _dateTimeData = DateTimeData();
    int index = 0;
    _selectData = PDuration();

    /// 年
    if (dateItemModel.year) {
      index = 0;
      _dateTimeData.year = TimeUtils.calcYears();

      if (_initData.year != null) {
        index = _dateTimeData.year.indexOf(_initData.year);
        index = index < 0 ? 0 : index;
      }
      _selectData.year = _dateTimeData.year[index];
      scrollCtrl[DateType.Year] = FixedExtentScrollController(initialItem: index);
    }

    /// 月
    // 选中的月 用于之后 day 的计算
    int selectMonth = 1;
    if (dateItemModel.month) {
      index = 0;
      _dateTimeData.month = TimeUtils.calcMonth();

      if (_initData.month != null) {
        index = _dateTimeData.month.indexOf(_initData.month);
        index = index < 0 ? 0 : index;
      }
      selectMonth = _dateTimeData.month[index];
      _selectData.month = selectMonth;
      scrollCtrl[DateType.Month] = FixedExtentScrollController(initialItem: index);
    }

    /// 日
    if (dateItemModel.day) {
      index = 0;
      _dateTimeData.day = TimeUtils.calcDay(_initData.year, selectMonth);

      if (_initData.day != null) {
        index = _dateTimeData.day.indexOf(_initData.day);
        index = index < 0 ? 0 : index;
      }
      _selectData.day = _dateTimeData.day[index];
      scrollCtrl[DateType.Day] = FixedExtentScrollController(initialItem: index);
    }

    /// 时
    if (dateItemModel.hour) {
      index = 0;
      _dateTimeData.hour = TimeUtils.calcHour();

      if (_initData.hour != null) {
        index = _dateTimeData.hour.indexOf(_initData.hour);
        index = index < 0 ? 0 : index;
      }
      _selectData.hour = _dateTimeData.hour[index];
      scrollCtrl[DateType.Hour] = FixedExtentScrollController(initialItem: index);
    }

    /// 分
    if (dateItemModel.minute) {
      index = 0;
      _dateTimeData.minute = TimeUtils.calcMinAndSecond();

      if (_initData.minute != null) {
        index = _dateTimeData.minute.indexOf(_initData.minute);
        index = index < 0 ? 0 : index;
      }
      _selectData.minute = _dateTimeData.minute[index];
      scrollCtrl[DateType.Minute] = FixedExtentScrollController(initialItem: index);
    }

    /// 秒
    if (dateItemModel.second) {
      index = 0;
      _dateTimeData.second = TimeUtils.calcMinAndSecond();

      if (_initData.second != null) {
        index = _dateTimeData.second.indexOf(_initData.second);
        index = index < 0 ? 0 : index;
      }
      _selectData.second = _dateTimeData.second[index];
      scrollCtrl[DateType.Second] = FixedExtentScrollController(initialItem: index);
    }
  }

  @override
  void dispose() {
    scrollCtrl.forEach((key, value) {
      value.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: AnimatedBuilder(
        animation: widget.route.animation,
        builder: (BuildContext context, Widget child) {
          return ClipRect(
            child: CustomSingleChildLayout(
              delegate: _BottomPickerLayout(widget.route.animation.value,
                  showTitleActions: widget.route.showTitleBar, showMenu: widget.route.menu != null),
              child: GestureDetector(
                child: Material(
                  color: Colors.transparent,
                  child: _renderPickerView(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _setPicker(DateType dateType, int selectIndex) {
    // 如果是月或者年 可能会带动日的变化
    if (dateType == DateType.Year) {
      var selectYear = _dateTimeData.year[selectIndex];

      var resultDays = TimeUtils.calcDay(selectYear, _selectData.month);
      print('返回的天数：$resultDays');

      // 如果天数一样不用更新
      if (resultDays.length != _dateTimeData.month.length) {
        print('进来了');
        scrollCtrl[DateType.Day]?.jumpToItem(resultDays.length - 1);
        setState(() {
          _dateTimeData.day = resultDays;
        });
      }
    }else if(dateType == DateType.Month){
      var selectMonth = _dateTimeData.month[selectIndex];

      var resultDays = TimeUtils.calcDay(_selectData.year, selectMonth);
      print('返回的天数：$resultDays');

      // 如果天数一样不用更新
      if (resultDays.length != _dateTimeData.month.length) {
        print('进来了');
        todo 跳转
        scrollCtrl[DateType.Day]?.jumpToItem(resultDays.length - 1);
        setState(() {
          _dateTimeData.day = resultDays;
        });
      }
    }

    var selectValue = _dateTimeData.getListByName(dateType)[selectIndex];
    _selectData.setSingle(dateType, selectValue);
    _notifyLocationChanged();
  }

  void _notifyLocationChanged() {
    if (widget.route.onChanged != null) {
      widget.route.onChanged(_selectData);
    }
  }

  double _pickerFontSize(String text) {
    if (text == null || text.length <= 6) {
      return 18.0;
    } else if (text.length < 9) {
      return 16.0;
    } else if (text.length < 13) {
      return 12.0;
    } else {
      return 10.0;
    }
  }

  Widget _renderPickerView() {
    Widget itemView = _renderItemView();

    if (!widget.route.showTitleBar && widget.route.menu == null) {
      return itemView;
    }
    List viewList = <Widget>[];
    if (widget.route.showTitleBar) {
      viewList.add(_titleView());
    }
    if (widget.route.menu != null) {
      viewList.add(widget.route.menu);
    }
    viewList.add(itemView);

    return Column(children: viewList);
  }

  Widget _renderItemView() {
    // 选择器
    List<Widget> pickerList = [];

    if (dateItemModel.year) pickerList.add(pickerView(DateType.Year));
    if (dateItemModel.month) pickerList.add(pickerView(DateType.Month));
    if (dateItemModel.day) pickerList.add(pickerView(DateType.Day));
    if (dateItemModel.hour) pickerList.add(pickerView(DateType.Hour));
    if (dateItemModel.minute) pickerList.add(pickerView(DateType.Minute));
    if (dateItemModel.second) pickerList.add(pickerView(DateType.Second));

    return Container(
      height: _pickerHeight,
      color: widget.route.backgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: pickerList,
      ),
    );
  }

  Widget pickerView(DateType dateType) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: CupertinoPicker(
          scrollController: scrollCtrl[dateType],
          itemExtent: _pickerItemHeight,
          onSelectedItemChanged: (int selectIndex) => _setPicker(dateType, selectIndex),
          children: List.generate(_dateTimeData.getListByName(dateType).length, (int index) {
            String text = '${_dateTimeData.getListByName(dateType)[index]}${widget.route.suffix.getSingle(dateType)}';
            return Container(
                alignment: Alignment.center,
                child: Text(text,
                    style: TextStyle(color: widget.route.textColor, fontSize: _pickerFontSize(text)),
                    textAlign: TextAlign.start));
          }),
        ),
      ),
    );
  }

  // 选择器上面的view
  Widget _titleView() {
    final commitButton = Container(
      height: _pickerTitleHeight,
      child: FlatButton(
          onPressed: null, child: Text('确定', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16.0))),
    );

    final cancelButton = Container(
      alignment: Alignment.center,
      height: _pickerTitleHeight,
      child: FlatButton(
          onPressed: null,
          child: Text('取消', style: TextStyle(color: Theme.of(context).unselectedWidgetColor, fontSize: 16.0))),
    );

    final headDecoration = BoxDecoration(color: Colors.white);

    return Container(
      height: _pickerTitleHeight,
      decoration: (widget.route.headDecoration == null) ? headDecoration : widget.route.headDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          /// 取消按钮
          InkWell(
              onTap: () => Navigator.pop(context),
              child: (widget.route.cancelWidget == null) ? cancelButton : widget.route.cancelWidget),

          /// 分割线
          (widget.route.title != null) ? widget.route.title : SizedBox(),

          /// 确认按钮
          InkWell(
              onTap: () {
                widget.route?.onConfirm(_selectData);
                Navigator.pop(context);
              },
              child: (widget.route.commitWidget == null) ? commitButton : widget.route.commitWidget)
        ],
      ),
    );
  }
}

class _BottomPickerLayout extends SingleChildLayoutDelegate {
  _BottomPickerLayout(this.progress, {this.itemCount, this.showTitleActions, this.showMenu});

  final double progress;
  final int itemCount;
  final bool showTitleActions;
  final bool showMenu;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    double maxHeight = _pickerHeight;
    if (showTitleActions) {
      maxHeight += _pickerTitleHeight;
    }
    if (showMenu) {
      maxHeight += _pickerMenuHeight;
    }

    return BoxConstraints(
        minWidth: constraints.maxWidth, maxWidth: constraints.maxWidth, minHeight: 0.0, maxHeight: maxHeight);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double height = size.height - childSize.height * progress;
    return Offset(0.0, height);
  }

  @override
  bool shouldRelayout(_BottomPickerLayout oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
