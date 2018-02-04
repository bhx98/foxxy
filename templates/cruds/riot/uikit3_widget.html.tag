<@{{object}}_edit>

  <ul uk-tab>
    <li><a href="#">@{{objects}}</a></li>
    <li each={ i, k in sub_models }><a href="#">{ k }</a></li>
  </ul>

  <ul class="uk-switcher uk-margin">
    <li>
      <h3>Editing @{{object}}</h3>
      <form onsubmit="{ save_form }" class="uk-form" id="form_@{{object}}">
      </form>
    </li>
    <li each={ i, k in sub_models }>
      <div id={ k } class="crud"></div>
    </li>
  </ul>

  <script>
    save_form(e) {
      e.preventDefault()
      common.saveForm("form_@{{object}}", "cruds/@{{objects}}",opts.@{{object}}_id)
    }

    var _this = this;
    common.get(url + "/cruds/@{{objects}}/" + opts.@{{object}}_id, function(d) {
      _this.@{{object}} = d.data
      _this.fields = d.fields
      _this.sub_models = d.fields.sub_models
      var fields = d.fields

      if(!_.isArray(fields)) fields = fields.model

      common.buildForm(_this.@{{object}}, fields, '#form_@{{object}}', '@{{objects}}', function() {
          $(".crud").each(function(i, c) {
          var id = $(c).attr("id")
          riot.mount("#" + id, "crud_index", { model: id,
            fields: _this.sub_models[id].fields,
            key: _this.sub_models[id].key,
            singular: _this.sub_models[id].singular,
            columns: _this.sub_models[id].columns,
            parent_id: opts.@{{object}}_id,
            parent_name: "@{{objects}}" })
        })
      })
    })
    this.on('updated', function() {
      $(".select_list").select2()
      $(".select_mlist").select2()
      $(".select_tag").select2({ tags: true })
    })
  </script>
</@{{object}}_edit>

<@{{object}}_new>
  <h3>Creating @{{object}}</h3>
  <form onsubmit="{ save_form }" class="uk-form" id="form_new_@{{object}}">
  </form>
  <script>
    save_form(e) {
      e.preventDefault()
      common.saveForm("form_new_@{{object}}", "cruds/@{{objects}}")
    }

    common.get(url + "/cruds/@{{objects}}/fields", function(d) {
      // Ignore sub models if any
      var fields = d.fields
      if(!_.isArray(fields)) fields = fields.model
      common.buildForm({}, fields, '#form_new_@{{object}}', '@{{objects}}');
    })
    this.on('updated', function() {
      $(".select_list").select2()
      $(".select_mlist").select2()
      $(".select_tag").select2({ tags: true })
    })
  </script>
</@{{object}}_new>

<@{{objects}}>
  <div class="uk-float-right">
    <a href="/#@{{objects}}/new" class="uk-button uk-button-small uk-button-default">New @{{object}}</a>

  </div>
  <h3>Listing @{{objects}}</h3>

  <form onsubmit={filter} class="uk-margin-top">
    <div class="uk-inline uk-width-1-1">
      <span class="uk-form-icon" uk-icon="icon: search"></span>
      <input type="text" ref="term" id="term" class="uk-input" autocomplete="off">
    </div>
  </form>
  <table class="uk-table uk-table-striped">
    <thead>
      <tr>
        <th each={ col in cols }>{col}</th>
        <th width="70"></th>
      </tr>
    </thead>
    <tbody>
      <tr each={ row in data } >
        <td each={ col in cols }>{row[col]}</td>
        <td class="uk-text-center" width="110">
          <a onclick={edit} class="uk-button uk-button-primary uk-button-small" uk-icon="icon: pencil"></a>
          <a onclick={ destroy_object } class="uk-button uk-button-danger uk-button-small" uk-icon="icon: trash"></a>
        </td>
      </tr>
    </tbody>

  </table>
  <ul class="uk-pagination">
    <li if={ page > 0 } ><a onclick={ previousPage }><span class="uk-margin-small-right" uk-pagination-previous></span> Previous</a></li>
    <li if={ (page + 1) * perpage < count} class="uk-margin-auto-left"><a onclick={ nextPage }>Next <span class="uk-margin-small-left" uk-pagination-next></span></a></li>
  </ul>
  <script>

    var _this = this
    this.page = 0
    this.perpage = 25
    this.locale = window.localStorage.getItem('foxx-locale')

    this.loadPage = function(pageIndex) {
      common.get(url + "/cruds/@{{objects}}/page/"+pageIndex, function(d) {
        _this.data = d.data[0].data
        _this.cols = common.array_diff(common.keys(_this.data[0]), ["_id", "_key", "_rev"])
        _this.count = d.data[0].count
        _this.update()
      })
    }
    this.loadPage(1)

    filter(e) {
      e.preventDefault();
      if(_this.refs.term.value != "") {
        $(".uk-form-icon i").attr("class", "uk-icon-spin uk-icon-spinner")
        common.get(url + "/cruds/@{{objects}}/search/"+_this.refs.term.value, function(d) {
          _this.data = d.data
          $(".uk-form-icon i").attr("class", "uk-icon-search")
          _this.update()
        })
      }
      else {
        _this.loadPage(1)
      }
    }

    edit(e) {
      route("/@{{objects}}/" + e.item.row._key + "/edit")
    }

    nextPage(e) {
      _this.page += 1
      _this.loadPage(_this.page + 1)
    }

    previousPage(e) {
      _this.page -= 1
      _this.loadPage(_this.page + 1)
    }

    destroy_object(e) {
      UIkit.modal.confirm("Are you sure?").then(function() {
        common.delete(url + "/cruds/@{{objects}}/" + e.item.row._key, function() {
          common.get(url + "/cruds/@{{objects}}/page/1", function(d) {
            _this.data = d.data[0].data
            _this.count = d.data[0].count
            _this.update()
          })
        })
      }, function() {})
    }

  </script>
</@{{objects}}>

