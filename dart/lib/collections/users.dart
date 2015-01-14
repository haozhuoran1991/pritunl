library users;

import 'package:pritunl/exceptions.dart';

import 'package:pritunl/collection.dart' as collection;
import 'package:pritunl/models/user.dart' as user;

import 'package:angular/angular.dart' show Injectable;
import 'package:angular/angular.dart' as ng;
import 'dart:math' as math;

@Injectable()
class Users extends collection.Collection {
  var _search;
  var _hasClients;
  var model = user.User;
  var orgId;
  var hidden;
  var page;
  var pageTotal;
  var pages;
  var searchCount;
  var searchMore;
  var searchTime;
  var searchLimit;

  get url {
    var url = '/user/${this.orgId}';

    if (this.search != null) {
      url += '?search=${this.search}';
      if (this.searchLimit != null) {
        url += '&limit=${this.searchLimit}';
      }
    }
    else {
      url += '?page=${this.page}';
    }

    return url;
  }

  set search(val) {
    if (val == '') {
      val = null;
    }

    this._search = val;
    this.fetch();
  }
  get search {
    return this._search;
  }

  get noUsers {
    if (this._hasClients == true || (
        this.hidden == true && this.length != 0)) {
      return false;
    }
    return true;
  }

  Users(ng.Http http) :
    page = 0,
    super(http);

  parse(data) {
    if (data.containsKey('search')) {
      if (this._search != data['search']) {
        throw new IgnoreResponse();
      }
      this.searchCount = data['search_count'];
      this.searchMore = data['search_more'];
      this.searchTime = data['search_time'];
      this.searchLimit = data['search_limit'];

      this.pageTotal = null;
    }
    else {
      if (this.page != data['page'].toInt()) {
        throw new IgnoreResponse();
      }
      this.pageTotal = data['page_total'].toInt();

      this.searchCount = null;
      this.searchMore = null;
      this.searchTime = null;
      this.searchLimit = null;

      this._updatePages();
    }

    return data['users'];
  }

  imported() {
    var user;

    for (user in this) {
      if (user.type == 'client') {
        this._hasClients = true;
        return;
      }
    }
    this._hasClients = false;
  }

  _updatePages() {
    this.pages = [];

    if (this.pageTotal < 2) {
      return;
    }

    var i;
    var isCurPage;
    var cur = math.max(0, this.page - 7);

    this.pages.add([this.page == 0, 'First']);

    for (i = 0; i < 15; i++) {
      isCurPage = cur == this.page;
      if (cur > this.pageTotal - 1) {
        break;
      }
      if (cur > 0) {
        this.pages.add([isCurPage, cur + 1]);
      }
      cur += 1;
    }

    pages.add([isCurPage, 'Last']);

    this.pages = pages;
  }

  next() {
    this.page += 1;
    this.fetch();
  }

  prev() {
    this.page -= 1;
    this.fetch();
  }

  onPage(page) {
    if (page == 'First') {
      page = 0;
    }
    else if (page == 'Last') {
      page = this.pageTotal;
    }
    else {
      page -= 1;
    }
    this.page = page;
    this.fetch();
  }

  searchIncrease() {
    this.searchLimit *= 2;
    this.fetch();
  }
}