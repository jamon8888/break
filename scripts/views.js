var cradle = require('cradle');

cradle.setup({ host: 'localhost',
               port: 5984,
               /*
                *options: { cache:true, raw: false }
                */
               });

var cclient = new (cradle.Connection)

function _createdb(dbname) {
    var db = cclient.database(dbname);
    db.exists(function(err, exists) {
        if (!exists) {
            db.create()
        }
    });
    return db;
}
var DB_TEST= _createdb('test')
/*
 *var DB_DATA= _createdb('data')
 */

function cradle_error(err, res) {
    if (err) console.log(err)
}

/*
 *if doc doesn't have type - split id by /, take first and remove 's' and set as type
 */

function update_views(db, docpath, code) {
    function save_doc() {
        db.save(docpath, code, cradle_error);
        return true;
    }
    // compare function definitions in document and in code
    function compare_def(docdef, codedef) {
        var i = 0;
        if (!codedef && !docdef) {
            return false;
        }
        if ((!docdef && codedef) || (!codedef && docdef)) {
            console.log('new definitions - updating "' + docpath +'"')
            return true;
        }
        for (var u in docdef) {
            i++;
            if (!codedef[u] || docdef[u] != codedef[u].toString()) {
                console.log('definition of "' + u + '" changed - updating "' + docpath +'"')
                return true;
            }
        }
        // check that both doc and code have same number of functions
        for (var u in codedef) {
            i--;
            if (i < 0) {
                console.log('new definitions - updating "' + docpath +'"')
                return true;
            }
        }
        return false;
    }
    db.get(docpath, function(err, doc) {
        if (!doc) {
            console.log('no design doc found updating "' + docpath +'"')
            return save_doc();
        }
        if (compare_def(doc.updates, code.updates) || compare_def(doc.views, code.views)) {
            return save_doc();
        }
        console.log('"' + docpath +'" up to date')
    });
}

var VENUES_DDOC = {
    language: 'javascript',
    views: {
        /*
         *byDate
         *byPublished
         */

        active: {
            map: function (doc) {
                if (doc.lastsession) {
                    emit(parseInt(doc.lastsession / 1000), 1)
                }
            },
            reduce: function(keys, counts, rereduce) {
                return sum(counts)
            }
        },
        users: function(doc) {
            if (doc.created) {
                emit(parseInt(doc.created / 1000), 1)
            }
        }
    }
}

var EVENTS_DDOC = {
    language: 'javascript',
    views: {
        /*
         *countByVenue
         *countByArtist
         *byVenue
         *byArtist
         */
        myview: function(doc) {
            if (doc.param1 && doc.param2) {
                emit([doc.param1, doc.param2], null)
            }
        }
    }
}

var ARTISTS_DDOC = {
    language: 'javascript',
    views: {
        myview: function(doc) {
            if (doc.param1 && doc.param2) {
                emit([doc.param1, doc.param2], null)
            }
        }
    }
}


function update_type(db) {
  db.all(function(err, doc) {
      /* Loop through all documents. */
      for(var i = 0; i < doc.length; i++) {
          /* Don't delete design documents. */
          if(doc[i].id.indexOf("_design") == -1) {
              if (doc[i].type == undefined) {
                var id = doc[i].id
                var newid = id.replace(/\//g, '%2F');
                if (id.split('/')[1] != null) {
                  var type = id.split('/')[1].slice(0, -1);
                  db.merge(newid, {type: type}, function(err, d) {
                    console.log(d)
                  })
                }
              }
          }
      }
  });
}

update_type(DB_TEST)
/*
 *update_views(DB_TEST, '_design/venues', VENUES_DDOC)
 *update_views(DB_TEST, '_design/events', EVENTS_DDOC)
 *update_views(DB_TEST, '_design/artists', ARTISTS_DDOC)
 */
