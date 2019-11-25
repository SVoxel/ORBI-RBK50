$$("#add_type").hide();
$$.fn.filterSelect = (function(){
    var isInit = false;
    function initCss(){
        isInit = true;
        var style = document.createElement("style");
        var csstext = '.m-input-select{display:inline-block;*display:inline;position:relative;-webkit-user-select:none;width:350px;}\
        \n.m-input-select ul, .m-input-select li{padding:0;margin:0;}\
        \n.m-input-select .m-input{padding-right:22px;width:325px;}\
        \n.m-input-select .m-input-ico{position:absolute;right:0;top:0;height:21px;line-height:21px;border-left:solid;border-left-width:1px;border-left-color:grey;padding-left:8px;padding-right:8px;}\
        \n.m-input-select .m-list-wrapper{}\
        \n.m-input-select .m-list{display:none;position:absolute;z-index:1;top:100%;left:0;right:0;max-width:100%;max-height:250px;overflow:auto;border-bottom:1px solid #ddd;}\
        \n.m-input-select .m-list-item{cursor:default;padding:5px;margin-top:-1px;list-style:none;background:#fff;border:1px solid #ddd;border-bottom:none;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}\
        \n.m-input-select .m-list-item:hover{background:#2D95FF;color:white;}\
        \n.m-input-select .m-list-item-active{background:#2D95FF;color:white;}\
        \n.m-list-remove{position:absolute;right:6px;padding-right:2px;padding-left:2px;cursor:pointer;}\
        \ninput[type="text"]::-ms-clear{display:none;}';
        style = $$("<style>"+ csstext +"</style>")[0];

        var head = document.head || document.getElementsByTagName("head")[0];
        if(head.hasChildNodes()){
            head.insertBefore(style, head.firstChild);
        }else{
            head.appendChild(style);
        };
    };

    return function(){
        !isInit && initCss();

        var $$body = $$("body");
        this.each(function(i, v){
            var $$sel = $$(v);
			var $$div = $$('<div class="m-input-select"></div>');
            var $$input = $$("<input type='text' class='m-input' />");
            var $$wrapper = $$("<ul class='m-list'></ul>");
            $$div = $$sel.wrap($$div).hide().addClass("m-select").parent();
            $$div.append($$input).append("<span class='m-input-ico' style='display:none;'></span>").append($$wrapper);

            var wrapper = {
                show: function(){
                    $$wrapper.show();
                    this.$$list = $$wrapper.find(".m-list-item:visible");
                    this.setIndex(this.$$list.filter(".m-list-item-active"));
                    this.setActive(this.index);
                },
                hide: function(){
                    $$wrapper.hide();
                },
                next: function(){
                    return this.setActive(this.index + 1);
                },
                prev: function(){
                    return this.setActive(this.index - 1);
                },
                $$list: $$wrapper.find(".m-list-item"),
                index: 0,
                $$cur: [],
                setActive: function(i){
                    var $$list = this.$$list, size = $$list.length;
                    if(size <= 0){
                        this.$$cur = [];
                        return;
                    }
                    $$list.filter(".m-list-item-active").removeClass("m-list-item-active");
                    if(i < 0){
                        i = 0;
                    }else if(i >= size){
                        i = size - 1;
                    }
                    this.index = i;
                    this.$$cur = $$list.eq(i).addClass("m-list-item-active");
                    this.fixScroll(this.$$cur);
                    return this.$$cur;
                },
                fixScroll: function($$elem){

                    var height = $$wrapper.height(), top = $$elem.position().top, eHeight = $$elem.outerHeight();
                    var scroll = $$wrapper.scrollTop();
                    top += scroll;
                    if(scroll > top){
                        $$wrapper.scrollTop(top);
                    }else if(top + eHeight > scroll + height){

                        $$wrapper.scrollTop(top + eHeight - height);
                    }
                },
                setIndex: function($$li){
                    if($$($$li).length > 0){
                        this.index = this.$$list.index($$li);
                        $$($$li).addClass("m-list-item-active").siblings().removeClass("m-list-item-active");
                    }else{
                        this.index = 0;
                    }
                }
            };

            var operation = {
                textChange: function(){
                    val = $$.trim($$input.val());
                    var itemNum = 0;
                    $$wrapper.find(".m-list-item").each(function(i, v){
                        if(v.innerHTML.toLowerCase().indexOf(val.toLowerCase()) >= 0){
                            $$(v).show();
                            itemNum++
                        }else{
                            $$(v).hide();
                        }
                    });
                    $$(".m-input-ico").text(itemNum);
					/*if(itemNum == 0)
						$$("#add_type").css("visibility", "visible");
					else
						$$("#add_type").css("visibility", "hidden");*/
                    wrapper.show();
                },
                setValue: function($$li){
                    if($$li && $$li.length > 0){
                        var cloneObj = $$li.clone();
                        cloneObj.find("span").remove();
                        var val = $$.trim(cloneObj.text());
                        $$input.val(val).attr("placeholder", val);
                        wrapper.setIndex($$li);
                        $$sel.val($$li.attr("data-value")).trigger("change");
                    }else{
                        $$input.val(function(i, v){
                            return $$input.attr("placeholder");
                        });
                    };
                    wrapper.hide();
                    this.offBody();
                },
                onBody: function(){
                    var self = this;
                    setTimeout(function(){
                        self.offBody();
                        $$body.on("click", self.bodyClick);
                    }, 10);
                },
                offBody: function(){
                    $$body.off("click", this.bodyClick);
                },
                bodyClick: function(e){
                    var target = e.target;
                    if(target != $$input[0] && target != $$wrapper[0]){
                        wrapper.hide();
                        operation.setValue();
                        operation.offBody();
                        $$(".m-input-ico").text($$("ul.m-list>li").length);
                        operation.setValue($$("li.m-list-item").eq($$("select").get(0).selectedIndex));
                    }
                }
            };

            function resetOption(){
                var html = "", val = "";
                $$sel.find("option").each(function(i, v){
                    if(v.selected && !val){
                        val = v.text;
                    };
                    html += '<li class="m-list-item'+ (v.selected ? " m-list-item-active" : "") +'" data-value="'+ v.value +'">'+ v.text;
                    if(v.value.indexOf("T-") != -1)
                        html += '<span class="m-list-remove">X</span>';
                    html += '</li>';
                });

                $$input.val(val);
                $$wrapper.html(html);
                $$(".m-input-ico").text($$("ul.m-list>li").length);
            };

            $$sel.on("optionChange", resetOption).trigger("optionChange");
            $$sel.on("setEditSelectValue", function(e, val){
                var $$all = $$wrapper.find(".m-list-item"), $$item;
                for(var i = 0, max = $$all.size(); i < max; i++){
                    $$item = $$all.eq(i);
                    if($$item.attr("data-value") == val){
                        operation.setValue($$item);
                        return;
                    }
                }
            });

            $$input.on("focus", function(){
                this.value = "";
                operation.textChange();
                operation.onBody();
            }).on("input propertychange", function(e){
                operation.textChange();
            }).on("keydown", function(e){
                switch(e.keyCode){
                    case 38:
                        wrapper.prev();
                        break;
                    case 40:
                        wrapper.next();
                        break;
                    case 13:
                        operation.setValue(wrapper.$$cur);
                        break;
                }
            });

            $$div.on("click", ".m-input-ico", function(){
                $$wrapper.is(":visible") ? $$input.blur() : ($$input.val("").trigger("focus"));
            });

            $$wrapper.on("click", ".m-list-item", function(){
                operation.setValue($$(this));
                return false;
            });

            /*function bind_delete_event() {
                $$("li.m-list-item>span").each(function(k, v){
                    $$(v).on("click", function(e){
                        var t = $$(this).parent().attr("data-value");
                        $$.ajax({
                            url: "/apply.cgi?/ajax_callback.txt timestamp=" + ts,
                            type: "POST",
                            data: "submit_flag=del_dev_type"+"&old_type_id=" + t,
                            dataType: "text",
                            success: function(data){
                                if(data.indexOf("success") == -1) {
                                    alert("Delete device type failed.");
                                    return false;
                                }
                                ts = data.split("success ")[1];
                                $$("select>option[value='"+t+"']").remove();
                                $$("li.m-list-item[data-value='"+t+"']").remove();
                                $$("select>option[value='0']").get(0).selected = true;
                                //resetOption();
                                operation.setValue($$("li.m-list-item[data-value='0']"));
                                $$("select>option[value='0']").get(0).selected = true;
                                select_icon();
                                $$(".m-input").trigger("focus");
                                diyType.splice(t.slice(2), 1);
                                $$(this).parent().remove();
                                e.stopPropagation();
                            },
                            error: function(){
                                alert("Delete device type failed.");
                            }
                        })
                    })
                })
            }

			$$("#add_type").on("click", function(){
                var inputed = $$(".m-input").val();
                $$.ajax({
                    url: "/apply.cgi?/ajax_callback.txt timestamp=" + ts,
                    type: "POST",
                    data: "submit_flag=add_dev_type"+"&new_type_id=T-"+diyType.length+"&new_type_name="+inputed,
                    dataType: "text",
                    success: function(data){
                        if(data.indexOf("success") == -1) {
                            alert("Add device type failed.");
                            return false;
                        }
                        ts = data.split("success ")[1];
                        $$("<option value='T-"+diyType.length+"'>"+inputed+"</option>").appendTo("select");
                        $$("select>option:last").get(0).selected = true;
        				diyType.push(inputed);
        				resetOption();
                        operation.setValue($$("select>option:last"));
                        $$("select>option:last").get(0).selected = true;
                        select_icon();
                        $$(".m-input").trigger("focus");
                        bind_delete_event();
                    },
                    error: function(){
                        alert("Add device type failed.");
                    }
                })
			})*/

            setTimeout(function(){
                wrapper.hide();
            }, 1)
        });

        return this;
    };
})();
