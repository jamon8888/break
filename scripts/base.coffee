nodeio = require 'node.io'
sys = require('sys')
require('coffee-script')
_ = require("underscore")._
async = require 'async'
geo = require('geo')
kit = require('kit/kit.coffee')
models = require('kit/models.coffee')
Calais = require('calais').Calais
Backbone = require("backbone")
translate = require('translate')
readability = require('node-readability')
fs = require('fs')

class Base extends nodeio.JobClass
    that: @
    input: false
    links: (that, input, num, a) =>
        links = []
        async.forEachSeries input
            ,(data, b) =>
                title = data.title.replace(/\+/g, 'and').replace(/\s/g, '+')
                title = exports.utils.url.encode(title)
                #French
                link = 'http://www.google.fr/search?q=' + title + '&hl=' + that.lang
                #French
                #Last month
                #link = 'http://www.google.fr/search?q=' + title + '&hl=fr&tbs=qdr:m'
                #Only french
                #link = 'http://www.google.fr/search?q=' + title + '&hl=' + that.lang + '&tbs=lr:lang_1' + that.lang

                ##base
                #http://www.google.fr/search?
                ##query
                #q=coffee&
                ##language
                #hl=fr&
                ##filters
                #tbs=lr:lang_1fr,qdr:m&
                  ##date restrict
                  #qdr: (h|d|m|y)
                  ##language restrict
                  #lr:lang_1 (fr|en|es|de)
                  ##country
                  #ctr:countryFR
                ##when filtering original lang, use this as well
                #lr=lang_fr&
                ##when filtering country, use this as well
                #cr=countryFR&
                ##num results
                #num=10&

                #link = 'http://www.google.fr/search?q=' + 'Peintures' + '&hl=' + that.lang
                that.getHtml link, (err, $, html) =>
                    #if err?
                        #console.log('err')
                        ##that.retry()
                    #else
                    results = []
                    #try
                    $('a.l').each (a) ->
                        results.push a.attribs.href
                    links.push results
                    b()
                    #catch e
                        #console.log('catch')
                        #console.log(results)
                        #links.push results
                        #b()
            ,(err) =>
                a(links)

    images: (that, input, num, a) =>
        images = []
        async.forEachSeries input
            ,(data, b) =>
                title = data.title.replace(/\+/g, 'and').replace(/\s/g, '+')
                #link = 'http://www.google.com/search?as_q=' + title + '&hl=fr&biw=1920&bih=980&tbm=isch&btnG=Recherche+Google&as_epq=&as_oq=&as_eq=&as_sitesearch=&safe=off&as_st=y&tbs=isz:l&tbs=isz:lt,islt:vga'
                link = 'http://www.google.fr/search?q=' + title + '&hl=' + that.lang + '&um=1&ie=UTF-8&tbm=isch&source=og&sa=N&tab=wi&biw=1920&bih=980&tbs=isz:lt,islt:vga'
                #size:
                  #&tbs=isz:lt,islt:vga
                  #vga(640x480)
                  #svga(800x600)
                  #xga(1024x760)
                  #2mp(2mp) (2/4/6/8/10/12/15...)
                count = 0
                #free license
                #link = 'http://www.google.com/search?as_q=' + title + '&hl=fr&tbm=isch&btnG=Google+Search&as_epq=&as_oq=&as_eq=&as_sitesearch=&safe=off&as_st=y&tbs=isz:l,iur:f&biw=1920&bih=980'
                that.getHtml link, (err, $, html) =>
                    results = []
                    try
                        $('#ImgCont a').each (a) ->
                            if count < num then results.push a.attribs.href.split('&')[0].substr(15)
                              # %3F = ?
                              # %3D = =
                            count++
                        images.push results
                        b()
                    catch e
                        images.push results
                        b()
            ,(err) =>
                a(images)

    tags: (that, input, a) =>
        tags = []
        async.forEachSeries input
            ,(data, b) =>
                calais = new Calais('g4jcd4j6hvdsy62dte4en6v7')
                calais.set('content', data)
                results = []
                try
                    setTimeout(
                        calais.fetch (result) ->
                            _.each result, (r) -> results.push(r.name) if r.name
                            tags.push results
                            b()
                    , 500)
                catch e
                    tags.push results
                    b()
            ,(err) =>
                a(tags)

    #translate: (that, input, field, lang, from, to, a) =>
        #translations = []
        #async.forEachSeries input
            #,(data, b) =>
                #text = data[field][lang]
                #try
                    #translate.text {input:from,output:to}, text, (err, translated) ->
                        #translations.push translated
                        ##console.log(text)
                        ##console.log('results')
                        ##console.log(translated)
                        #b()
                #catch e
                    #translations.push ''
                    #b()
            #,(err) =>
                #a(translations)

    translate: (that, input, language, split, a) =>
        translations = {}
        async.forEachSeries that.langs
            ,(lang, b) =>
                unless lang is language
                    translations[lang] = []
                    async.forEachSeries input
                        ,(data, c) =>
                            if typeof data is 'object' and not split
                                results = []
                                async.forEachSeries data
                                    ,(text, d) =>
                                        text = text.replace("'", '&#39;')
                                        try
                                            translate.text {input:that.languages[language],output:that.languages[lang]}, text, (err, translated) ->
                                                results.push translated
                                                d()
                                        catch e
                                            results.push ''
                                            d()
                                    ,(err) =>
                                        translations[lang].push results
                                        c()
                            else
                                if split then text = data.join(', ').replace("'", '&#39;')
                                else text = data.replace("'", '&#39;')
                                try
                                    translate.text {input:that.languages[language],output:that.languages[lang]}, text, (err, translated) ->
                                        if split and translated then translations[lang].push translated.split(', ')
                                        else translations[lang].push translated
                                        c()
                                catch e
                                    translations[lang].push ''
                                    c()
                        ,(err) =>
                            b()
                else
                  b()
        , (err) =>
            a(translations)

    readable: (that, input, num, a) =>
        readable = []
        async.forEachSeries input
            ,(links, b) =>
                count = 0
                results = []
                async.whilst(
                    ->
                        count < num
                    , (c) =>
                        try
                            that.getHtml links[count], (err, $, html) =>
                                if err? then @retry()
                                else
                                    count++
                                    try
                                        readability.parse html, links[count], (result) =>
                                            results.push result.content
                                            c()
                                    catch e
                                        results.push ''
                                        c()
                        catch e
                            results.push ''
                            c()
                    , (err) =>
                        readable.push results
                        b()
                )
            ,(err) =>
                a(readable)

    geo: (that, input, country, a) =>
        addresses = []
        locations = []
        async.forEachSeries input
            ,(data, b) =>
                address = data.address + ' ' + country
                sensor = false
                try
                    geo.geocoder geo.google, address, sensor, (formattedAddress, latitude, longitude) ->
                        locations.push [latitude, longitude]
                        addresses.push formattedAddress
                        b()
                catch e
                    locations.push []
                    addresses.push ''
                    b()
            ,(err) =>
                a(addresses, locations)

    presave: (that, output, a) =>


    save: (that, output, a) =>
        async.series [
            (b) =>
                switch that.type
                    when 'v' then @coll = new models.venues()
                    when 'e' then @coll = new models.events()
                    when 'a' then @coll = new models.artists()

                if @coll
                    console.log('col')
                    #console.log(@coll)
                    @coll.fetch(
                        success: (collection, response) ->
                            b()
                        error: (collection, response) ->
                            b()
                    )
                else
                    console.log('no col')
                    b()
             ,(b) =>
                async.forEach(output
                    ,(data, c) =>
                        @coll.create(data,
                            success: (collection, response) ->
                              c()
                            error: (collection, response) ->
                              c()
                        )
                    ,(err) =>
                       b()
                )
             ,(b) =>
                out = ''
                _.each(that.output, (i) =>
                  out += JSON.stringify(i) + '\n'
                )
                fs.open that.file + '.txt', "a", 666, (e, id) ->
                  fs.write id, out, null, "utf8", ->
                    fs.close id, ->
                      b()
                #log = fs.createWriteStream that.file + '.txt', {'flags': 'a'}
                #that.write that.file + '.txt', that.output, =>
                    #b()
                    #@emit()
             ,(b) =>
                a()
        ]

    process: (a) =>
        #console.log(house)
        out =  JSON.stringify(@output)
        @emit(out)

#wiki
#html filter
##event name + critique
#10 images from current lang
#events, then venues/artists
#ignore dups + save last index
#error reporting in a page w/ dates

@class = Base
@job = new Base({timeout:300})

exports.utils = {}

exports.utils.date =
  monthFr: (string) =>
    switch string
      when 'jan' then return 1
      when 'janv' then return 1
      when 'janvier' then return 1
      when 'fév' then return 2
      when 'fev' then return 2
      when 'mar' then return 3
      when 'avr' then return 4
      when 'avri' then return 4
      when 'mai' then return 5
      when 'ma' then return 5
      when 'jun' then return 6
      when 'jui' then return 6
      when 'jul' then return 7
      when 'juil' then return 7
      when 'au' then return 8
      when 'aou' then return 8
      when 'aoû' then return 8
      when 'aout' then return 8
      when 'sep' then return 9
      when 'sept' then return 9
      when 'oct' then return 10
      when 'nov' then return 11
      when 'dec' then return 12
      when 'déc' then return 12
      else return null

  convertDate: (string) =>
    if typeof string is 'object'
      a = []
      _.each(string, (i, index, list) =>
        a[index] = i.split(' ')
        if a[index][1] then a[index][1] = a[index][1].slice(0, -1)
        if a[index][2] then a[index][2] = a[index][2].replace('\n', '')
      )
      unless a[0][2] then a[0][2] = a[1][2]
      b = {}
      b.from = new Date(a[0][2], @utils.date.monthFr(a[0][1]) - 1, parseFloat(a[0][0]), 12)
      b.to = new Date(a[1][2], @utils.date.monthFr(a[1][1]) - 1, parseFloat(a[1][0]), 12)
      return b
    else
      a = string.split(' ')
      if a[1] then a[1] = a[1].slice(0, -1)
      if a[2] then a[2] = a[2].replace('\n', '')
      if a[3]
        b = new Date(a[2], @utils.date.monthFr(a[1]) - 1, parseFloat(a[0]) + 1, a[3])
        return b
      else
        b = new Date(a[2], @utils.date.monthFr(a[1]) - 1, parseFloat(a[0]) + 1, 12)
        return b

exports.utils.url =
  encode: (string) ->
    escape @_utf8_encode(string)

  decode: (string) ->
    @_utf8_decode unescape(string)

  _utf8_encode: (string) ->
    string = string.replace(/\r\n/g, "\u000a")
    utftext = ""
    n = 0

    while n < string.length
      c = string.charCodeAt(n)
      if c < 128
        utftext += String.fromCharCode(c)
      else if (c > 127) and (c < 2048)
        utftext += String.fromCharCode((c >> 6) | 192)
        utftext += String.fromCharCode((c & 63) | 128)
      else
        utftext += String.fromCharCode((c >> 12) | 224)
        utftext += String.fromCharCode(((c >> 6) & 63) | 128)
        utftext += String.fromCharCode((c & 63) | 128)
      n++
    utftext

  _utf8_decode: (utftext) ->
    string = ""
    i = 0
    c = c1 = c2 = 0
    while i < utftext.length
      c = utftext.charCodeAt(i)
      if c < 128
        string += String.fromCharCode(c)
        i++
      else if (c > 191) and (c < 224)
        c2 = utftext.charCodeAt(i + 1)
        string += String.fromCharCode(((c & 31) << 6) | (c2 & 63))
        i += 2
      else
        c2 = utftext.charCodeAt(i + 1)
        c3 = utftext.charCodeAt(i + 2)
        string += String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63))
        i += 3
    string


exports.utils.html =
  # remove multiple, leading or trailing spaces, tabs and newlines(optional), and decodes html entities
  decode: (string, newline) ->
    newline ?= false
    hash_map = {}
    symbol = ""
    tmp_str = ""
    entity = ""
    tmp_str = string.toString()
    return false  if false == (hash_map = @_translation_table("HTML_ENTITIES"))
    delete (hash_map["&"])

    hash_map["&"] = "&amp;"
    for symbol of hash_map
      entity = hash_map[symbol]
      tmp_str = tmp_str.split(entity).join(symbol)
    tmp_str = tmp_str.split("&#039;").join("'")
                                     .replace(/(^\s*)|(\s*$)|(\t)/gi,"")
                                     .replace(/[ ]{2,}/gi," ")
                                     .replace(/\n /,"\n")
                                     .replace(/'/g, "&#39;")
                                     .replace(/«/g, '&quot;')
                                     .replace(/»/g, '&quot;')
    unless newline
      tmp_str = tmp_str.replace(/(\n)|(\r)/g, '')
    else
      tmp_str = tmp_str.replace(/\r/, '/n')
    tmp_str

  _translation_table: (table, quote_style) ->
    #removed quote_style
    entities = {}
    hash_map = {}
    decimal = 0
    symbol = ""
    constMappingTable = {}
    constMappingQuoteStyle = {}
    useTable = {}
    useQuoteStyle = {}
    constMappingTable[0] = "HTML_SPECIALCHARS"
    constMappingTable[1] = "HTML_ENTITIES"
    constMappingQuoteStyle[0] = "ENT_NOQUOTES"
    constMappingQuoteStyle[2] = "ENT_COMPAT"
    constMappingQuoteStyle[3] = "ENT_QUOTES"
    useTable = (if not isNaN(table) then constMappingTable[table] else (if table then table.toUpperCase() else "HTML_SPECIALCHARS"))
    useQuoteStyle = (if not isNaN(quote_style) then constMappingQuoteStyle[quote_style] else (if quote_style then quote_style.toUpperCase() else "ENT_COMPAT"))
    throw new Error("Table: " + useTable + " not supported")  if useTable != "HTML_SPECIALCHARS" and useTable != "HTML_ENTITIES"
    if useTable == "HTML_ENTITIES"
      entities["38"] = "&amp;"
      entities["160"] = "&nbsp;"
      entities["161"] = "&iexcl;"
      entities["162"] = "&cent;"
      entities["163"] = "&pound;"
      entities["164"] = "&curren;"
      entities["165"] = "&yen;"
      entities["166"] = "&brvbar;"
      entities["167"] = "&sect;"
      entities["168"] = "&uml;"
      entities["169"] = "&copy;"
      entities["170"] = "&ordf;"
      entities["171"] = "&laquo;"
      entities["172"] = "&not;"
      entities["173"] = "&shy;"
      entities["174"] = "&reg;"
      entities["175"] = "&macr;"
      entities["176"] = "&deg;"
      entities["177"] = "&plusmn;"
      entities["178"] = "&sup2;"
      entities["179"] = "&sup3;"
      entities["180"] = "&acute;"
      entities["181"] = "&micro;"
      entities["182"] = "&para;"
      entities["183"] = "&middot;"
      entities["184"] = "&cedil;"
      entities["185"] = "&sup1;"
      entities["186"] = "&ordm;"
      entities["187"] = "&raquo;"
      entities["188"] = "&frac14;"
      entities["189"] = "&frac12;"
      entities["190"] = "&frac34;"
      entities["191"] = "&iquest;"
      entities["192"] = "&Agrave;"
      entities["193"] = "&Aacute;"
      entities["194"] = "&Acirc;"
      entities["195"] = "&Atilde;"
      entities["196"] = "&Auml;"
      entities["197"] = "&Aring;"
      entities["198"] = "&AElig;"
      entities["199"] = "&Ccedil;"
      entities["200"] = "&Egrave;"
      entities["201"] = "&Eacute;"
      entities["202"] = "&Ecirc;"
      entities["203"] = "&Euml;"
      entities["204"] = "&Igrave;"
      entities["205"] = "&Iacute;"
      entities["206"] = "&Icirc;"
      entities["207"] = "&Iuml;"
      entities["208"] = "&ETH;"
      entities["209"] = "&Ntilde;"
      entities["210"] = "&Ograve;"
      entities["211"] = "&Oacute;"
      entities["212"] = "&Ocirc;"
      entities["213"] = "&Otilde;"
      entities["214"] = "&Ouml;"
      entities["215"] = "&times;"
      entities["216"] = "&Oslash;"
      entities["217"] = "&Ugrave;"
      entities["218"] = "&Uacute;"
      entities["219"] = "&Ucirc;"
      entities["220"] = "&Uuml;"
      entities["221"] = "&Yacute;"
      entities["222"] = "&THORN;"
      entities["223"] = "&szlig;"
      entities["224"] = "&agrave;"
      entities["225"] = "&aacute;"
      entities["226"] = "&acirc;"
      entities["227"] = "&atilde;"
      entities["228"] = "&auml;"
      entities["229"] = "&aring;"
      entities["230"] = "&aelig;"
      entities["231"] = "&ccedil;"
      entities["232"] = "&egrave;"
      entities["233"] = "&eacute;"
      entities["234"] = "&ecirc;"
      entities["235"] = "&euml;"
      entities["236"] = "&igrave;"
      entities["237"] = "&iacute;"
      entities["238"] = "&icirc;"
      entities["239"] = "&iuml;"
      entities["240"] = "&eth;"
      entities["241"] = "&ntilde;"
      entities["242"] = "&ograve;"
      entities["243"] = "&oacute;"
      entities["244"] = "&ocirc;"
      entities["245"] = "&otilde;"
      entities["246"] = "&ouml;"
      entities["247"] = "&divide;"
      entities["248"] = "&oslash;"
      entities["249"] = "&ugrave;"
      entities["250"] = "&uacute;"
      entities["251"] = "&ucirc;"
      entities["252"] = "&uuml;"
      entities["253"] = "&yacute;"
      entities["254"] = "&thorn;"
      entities["255"] = "&yuml;"
      entities["264"] = "&#264;"
      entities["265"] = "&#265;"
      entities["338"] = "&OElig;"
      entities["339"] = "&oelig;"
      entities["352"] = "&Scaron;"
      entities["353"] = "&scaron;"
      entities["372"] = "&#372;"
      entities["373"] = "&#373;"
      entities["374"] = "&#374;"
      entities["375"] = "&#375;"
      entities["376"] = "&Yuml;"
      entities["402"] = "&fnof;"
      entities["710"] = "&circ;"
      entities["732"] = "&tilde;"
      entities["913"] = "&Alpha;"
      entities["914"] = "&Beta;"
      entities["915"] = "&Gamma;"
      entities["916"] = "&Delta;"
      entities["917"] = "&Epsilon;"
      entities["918"] = "&Zeta;"
      entities["919"] = "&Eta;"
      entities["920"] = "&Theta;"
      entities["921"] = "&Iota;"
      entities["922"] = "&Kappa;"
      entities["923"] = "&Lambda;"
      entities["924"] = "&Mu;"
      entities["925"] = "&Nu;"
      entities["926"] = "&Xi;"
      entities["927"] = "&Omicron;"
      entities["928"] = "&Pi;"
      entities["929"] = "&Rho;"
      entities["931"] = "&Sigma;"
      entities["932"] = "&Tau;"
      entities["933"] = "&Upsilon;"
      entities["934"] = "&Phi;"
      entities["935"] = "&Chi;"
      entities["936"] = "&Psi;"
      entities["937"] = "&Omega;"
      entities["945"] = "&alpha;"
      entities["946"] = "&beta;"
      entities["947"] = "&gamma;"
      entities["948"] = "&delta;"
      entities["949"] = "&epsilon;"
      entities["950"] = "&zeta;"
      entities["951"] = "&eta;"
      entities["952"] = "&theta;"
      entities["953"] = "&iota;"
      entities["954"] = "&kappa;"
      entities["955"] = "&lambda;"
      entities["956"] = "&mu;"
      entities["957"] = "&nu;"
      entities["958"] = "&xi;"
      entities["959"] = "&omicron;"
      entities["960"] = "&pi;"
      entities["961"] = "&rho;"
      entities["962"] = "&sigmaf;"
      entities["963"] = "&sigma;"
      entities["964"] = "&tau;"
      entities["965"] = "&upsilon;"
      entities["966"] = "&phi;"
      entities["967"] = "&chi;"
      entities["968"] = "&psi;"
      entities["969"] = "&omega;"
      entities["977"] = "&thetasym;"
      entities["978"] = "&upsih;"
      entities["982"] = "&piv;"
      entities["8194"] = "&ensp;"
      entities["8195"] = "&emsp;"
      entities["8201"] = "&thinsp;"
      entities["8204"] = "&zwnj;"
      entities["8205"] = "&zwj;"
      entities["8206"] = "&lrm;"
      entities["8207"] = "&rlm;"
      entities["8211"] = "&ndash;"
      entities["8212"] = "&mdash;"
      entities["8216"] = "&lsquo;"
      entities["8217"] = "&rsquo;"
      entities["8218"] = "&sbquo;"
      entities["8220"] = "&ldquo;"
      entities["8221"] = "&rdquo;"
      entities["8222"] = "&bdquo;"
      entities["8224"] = "&dagger;"
      entities["8225"] = "&Dagger;"
      entities["8226"] = "&bull;"
      entities["8230"] = "&hellip;"
      entities["8240"] = "&permil;"
      entities["8242"] = "&prime;"
      entities["8243"] = "&Prime;"
      entities["8249"] = "&lsaquo;"
      entities["8250"] = "&rsaquo;"
      entities["8254"] = "&oline;"
      entities["8260"] = "&frasl;"
      entities["8364"] = "&euro;"
      entities["8472"] = "&weierp;"
      entities["8465"] = "&image;"
      entities["8476"] = "&real;"
      entities["8482"] = "&trade;"
      entities["8501"] = "&alefsym;"
      entities["8592"] = "&larr;"
      entities["8593"] = "&uarr;"
      entities["8594"] = "&rarr;"
      entities["8595"] = "&darr;"
      entities["8596"] = "&harr;"
      entities["8629"] = "&crarr;"
      entities["8656"] = "&lArr;"
      entities["8657"] = "&uArr;"
      entities["8658"] = "&rArr;"
      entities["8659"] = "&dArr;"
      entities["8660"] = "&hArr;"
      entities["8704"] = "&forall;"
      entities["8706"] = "&part;"
      entities["8707"] = "&exist;"
      entities["8709"] = "&empty;"
      entities["8711"] = "&nabla;"
      entities["8712"] = "&isin;"
      entities["8713"] = "&notin;"
      entities["8715"] = "&ni;"
      entities["8719"] = "&prod;"
      entities["8721"] = "&sum;"
      entities["8722"] = "&minus;"
      entities["8727"] = "&lowast;"
      entities["8729"] = "&#8729;"
      entities["8730"] = "&radic;"
      entities["8733"] = "&prop;"
      entities["8734"] = "&infin;"
      entities["8736"] = "&ang;"
      entities["8743"] = "&and;"
      entities["8744"] = "&or;"
      entities["8745"] = "&cap;"
      entities["8746"] = "&cup;"
      entities["8747"] = "&int;"
      entities["8756"] = "&there4;"
      entities["8764"] = "&sim;"
      entities["8773"] = "&cong;"
      entities["8776"] = "&asymp;"
      entities["8800"] = "&ne;"
      entities["8801"] = "&equiv;"
      entities["8804"] = "&le;"
      entities["8805"] = "&ge;"
      entities["8834"] = "&sub;"
      entities["8835"] = "&sup;"
      entities["8836"] = "&nsub;"
      entities["8838"] = "&sube;"
      entities["8839"] = "&supe;"
      entities["8853"] = "&oplus;"
      entities["8855"] = "&otimes;"
      entities["8869"] = "&perp;"
      entities["8901"] = "&sdot;"
      entities["8968"] = "&lceil;"
      entities["8969"] = "&rceil;"
      entities["8970"] = "&lfloor;"
      entities["8971"] = "&rfloor;"
      entities["9001"] = "&lang;"
      entities["9002"] = "&rang;"
      entities["9642"] = "&#9642;"
      entities["9643"] = "&#9643;"
      entities["9674"] = "&loz;"
      entities["9702"] = "&#9702;"
      entities["9824"] = "&spades;"
      entities["9827"] = "&clubs;"
      entities["9829"] = "&hearts;"
      entities["9830"] = "&diams;"
      entities["34"] = "&quot;"  if useQuoteStyle != "ENT_NOQUOTES"
      entities["39"] = "&#39;"  if useQuoteStyle == "ENT_QUOTES"
      entities["60"] = "&lt;"
      entities["62"] = "&gt;"
    for decimal of entities
      symbol = String.fromCharCode(decimal)
      hash_map[symbol] = entities[decimal]
    hash_map
