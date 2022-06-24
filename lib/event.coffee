if Meteor.isClient
    Router.route '/events/', (->
        @layout 'layout'
        @render 'events'
        ), name:'events'

    Router.route '/event/:doc_id/', (->
        @layout 'event_layout'
        @render 'event_dashboard'
        ), name:'event_home'
    Router.route '/event/:doc_id/edit', (->
        @layout 'layout'
        @render 'event_edit'
        ), name:'event_edit'
    Router.route '/event/:doc_id/:section', (->
        @layout 'event_layout'
        @render 'event_section'
        ), name:'event_section'
    Template.events.onCreated ->
        @autorun => Meteor.subscribe 'model_docs', 'event', ->
            
            
    Template.events.helpers 
        event_docs: ->
            Docs.find {
                model:'event'
            }, sort: _timestamp:-1
            
        one_result: ->
            Docs.find({model:'event'}).count() is 1
        
        room_button_class: -> 
            if Session.equals('viewing_room_id', @_id) then 'blue' else 'basic'
        event_docs: ->
            # console.log moment().format()
            match = {}
            match.model = 'event'
            # published:true
            if picked_tags.array().length > 0
                match.tags = $all: picked_tags
            
            # if Session.get('viewing_past')
            #     # match.date = $gt:moment().subtract(1,'days').format("YYYY-MM-DD")
            #     match.start_datetime = $lt:moment().subtract(1,'days').format()
            # else if Session.get('view_mode', 'all')
            #     match.start_datetime = $gt:moment().subtract(1,'days').format()
            # else
            #     match.date = $lt:moment().subtract(1,'days').format("YYYY-MM-DD")
            if Session.get('event_search')
                match.title = {$regex:"#{Session.get('event_search')}", $options: 'i'}
            Docs.find match,
                sort:"#{Session.get('sort_key')}":parseInt(Session.get('sort_direction'))
            
            
    Template.event_edit.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.event_layout.onCreated ->
        # @autorun => Meteor.subscribe 'product_from_transfer_id', Router.current().params.doc_id, ->
        @autorun => Meteor.subscribe 'author_from_doc_id', Router.current().params.doc_id, ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.event_section.helpers
        section_template: -> "event_#{Router.current().params.section}"


if Meteor.isClient
    # Template.event_edit.onCreated ->
    #     @autorun => Meteor.subscribe 'model_docs', 'room_reservation'
    #     @autorun => Meteor.subscribe 'model_docs', 'room'
    Template.event_edit.helpers
        rooms: ->
            Docs.find   
                model:'room'

    Template.event_edit.helpers
        reservation_exists: ->
            event = Docs.findOne Router.current().params.doc_id
            Docs.findOne
                model:'room_reservation'
                # room_id:event.room_id 
                date:event.date
        room_button_class: ->
            event = Docs.findOne Router.current().params.doc_id
            room = Docs.findOne _id:event.room_id
            reservation_exists = 
                Docs.findOne
                    model:'room_reservation'
                    # room_id:event.room_id 
                    date:event.date
            res = ''
            if event.room_id is @_id
                res += 'blue'
            else 
                res += 'basic'
            if reservation_exists
                # console.log 'res exists'
                res += ' disabled'
            else
                console.log 'no res'
            res
    
        room_reservations: ->
            event = Docs.findOne Router.current().params.doc_id
            room = Docs.findOne _id:event.room_id
            Docs.find 
                model:'room_reservation'
                room_id:event.room_id 
                date:event.date


    Template.event_edit.events
        'click .delete_item': ->
            if confirm 'delete event?'
                Docs.remove @_id
            Router.go "/events"

        'click .select_room': ->
            reservation_exists = 
                Docs.findOne
                    model:'room_reservation'
                    room_id:event.room_id 
                    date:event.date
            console.log reservation_exists
            unless reservation_exists            
                Docs.update Router.current().params.doc_id,
                    $set:
                        room_id:@_id
                        room_title:@title

        'click .submit': ->
            Docs.update Router.current().params.doc_id,
                $set:published:true
            if confirm 'confirm?'
                Meteor.call 'send_event', @_id, =>
                    Router.go "/event/#{@_id}/view"


                
    Template.reserve_button.helpers
        event_room: ->
            event = Docs.findOne Router.current().params.doc_id
            room = Docs.findOne _id:event.room_id
        slot_res: ->
            event = Docs.findOne Router.current().params.doc_id
            room = Docs.findOne _id:event.room_id
            Docs.findOne
                model:'room_reservation'
                room_id:event.room_id
                date:event.date
                slot:@slot
    
    
    Template.reserve_button.events
        'click .cancel_res': ->
            Swal.fire({
                title: "confirm delete reservation?"
                text: ""
                icon: 'question'
                showCancelButton: true,
                confirmButtonText: 'confirm'
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Docs.remove @_id
            )
        'click .reserve_slot': ->
            event = Docs.findOne Router.current().params.doc_id
            room = Docs.findOne _id:event.room_id
            Docs.insert 
                model:'room_reservation'
                room_id:event.room_id
                date:event.date
                slot:@slot
                payment:'points'
                
