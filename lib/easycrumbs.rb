require "easycrumbs/collection"
require "easycrumbs/view_helpers"
require "easycrumbs/breadcrumb"
require "easycrumbs/errors"

ActionView::Base.send :include, EasyCrumbs::ViewHelpers