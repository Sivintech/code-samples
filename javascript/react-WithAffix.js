import React                    from 'react';
import _                        from 'underscore';
import classnames               from 'classnames';
import {getFrameInScreen}       from 'DomUtils';

/* USAGE EXAMPLE:

This component is designed to support slick affixes when main page takes 100%
height, and all scrolling happens in one "overflow: auto" div, and also more
complex affixes which look a bit differently when fixed.

WithAffix toggles it's own "affix-parent-active" CSS class when affix is
supposed to have a fixed position, and also passes down "affix" prop to it's
children, including hints on whether affix is currently active, and which
left, top, and width values should fixed component have to match it's non-fixed
counterpart.

<WithAffix scrollParentId="pageContent" topOffset="20">
  <ChildComponentThatSupportsANiceAffix/>
</WithAffix>

*/

export default class WithAffix extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      affix: {
        active: false,
        left:   0,
        top:    0,
        width:  1024
      }
    };
  }

  componentDidMount() {
    this._refreshState();
    this._initDomListeners();
  }

  componentWillUnmount() {
    this._tearDownDomListeners();
  }

  _refreshState() {
    if (this._scrollChild) {
      const parentEl = this._getParentEl();
      const childEl = this._getChildEl();

      const parentFrameInDocument = getFrameInScreen(parentEl);
      const childFrameInDocument = getFrameInScreen(childEl);
      const childTopInParent = childFrameInDocument.y - parentFrameInDocument.y;

      const affix = Object.assign({}, this.state.affix, {
        active: childTopInParent < this.props.topOffset,
        top:    parentFrameInDocument.y,
        left:   childFrameInDocument.x,
        width:  childFrameInDocument.width
      });

      if (!_(this.state.affix).isEqual(affix)) {
        this.setState({affix});
      }
    }
  }

  _attachAffix(el) {
    this._scrollChild = el;
    this._refreshState();
  }

  _initDomListeners() {
    this._refreshListener = () => this._refreshState();
    this._getParentEl().addEventListener('scroll', this._refreshListener);
    window.addEventListener('resize', this._refreshListener);
  }

  _tearDownDomListeners() {
    this._getParentEl().removeEventListener('scroll', this._refreshListener);
    window.removeEventListener('resize', this._refreshListener);
    this._refreshListener = null;
  }

  _getParentEl() {
    const bodyEl = document.getElementById(this.props.scrollParentId);
    if (!bodyEl) {
      throw new Error('WithAffix: scroll parent specified incorrectly');
    }
    return bodyEl;
  }

  _getChildEl() {
    if (this._scrollChild) {
      return this._scrollChild;
    } else {
      throw new Error('WithAffix: affix child not attached');
    }
  }

  _childProps() {
    return {
      affix: Object.assign({}, this.state.affix, {
        attach: (el) => this._attachAffix(el),

        style:  {
          left:  this.state.affix.left,
          top:   this.state.affix.top,
          width: this.state.affix.width
        }
      })
    };
  }

  render() {
    const childProps = this._childProps();

    return (
      <div className={classnames('affix-parent', {'affix-parent-active': this.state.affix.active})}>

        {React.Children.map(this.props.children,
          (child) => React.cloneElement(child, childProps))}
      </div>
    );
  }
}
WithAffix.propTypes = {
  scrollParentId: React.PropTypes.string,
  topOffset:      React.PropTypes.number
};
WithAffix.defaultProps = {scrollParentId: 'main-content', topOffset: 0};
