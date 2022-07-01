if Meteor.isClient
    Template.event_layout.onCreated ->
        @autorun => Meteor.subscribe 'author_by_doc_id', Router.current().params.doc_id
        # @autorun => Meteor.subscribe 'author_by_doc_slug', Router.current().params.doc_slug
        @autorun => Meteor.subscribe 'event_tickets', Router.current().params.doc_id
        # @autorun => Meteor.subscribe 'model_docs', 'room'
        
        # if Meteor.isDevelopment
        #     pub_key = Meteor.settings.public.stripe_test_publishable
        # else if Meteor.isProduction
        #     pub_key = Meteor.settings.public.stripe_live_publishable
        # Template.instance().checkout = StripeCheckout.configure(
        #     key: pub_key
        #     image: 'https://res.cloudinary.com/facet/image/upload/v1585357133/one_logo.png'
        #     locale: 'auto'
        #     zipCode: true
        #     token: (token) =>
        #         # amount = parseInt(Session.get('topup_amount'))
        #         event = Docs.findOne Router.current().params.doc_id
        #         charge =
        #             amount: Session.get('usd_paying')*100
        #             event_id:event._id
        #             currency: 'usd'
        #             source: token.id
        #             input:'number'
        #             # description: token.description
        #             description: "one"
        #             event_title:event.title
        #             # receipt_email: token.email
        #         Meteor.call 'buy_ticket', charge, (err,res)=>
        #             if err then alert err.reason, 'danger'
        #             else
        #                 console.log 'res', res
        #                 Swal.fire(
        #                     'ticket purchased',
        #                     ''
        #                     'success'
        #                 # Meteor.users.update Meteor.userId(),
        #                 #     $inc: points:500
        #                 )
        # )
    
    Template.event_layout.onRendered ->
        Docs.update Router.current().params.doc_id, 
            $inc: views: 1

    Template.event_layout.helpers 
        can_buy: ->
            now = Date.now()
            

    Template.event_layout.events
        'click .buy_for_points': (e,t)->
            val = parseInt $('.point_input').val()
            Session.set('point_paying',val)
            # $('.ui.modal').modal('show')
            Swal.fire({
                title: "buy ticket for #{Session.get('point_paying')}pts?"
                text: "#{@title}"
                icon: 'question'
                # input:'number'
                confirmButtonText: 'purchase'
                confirmButtonColor: 'green'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Docs.insert 
                        model:'transaction'
                        transaction_type:'ticket_purchase'
                        payment_type:'points'
                        is_points:true
                        point_amount:Session.get('point_paying')
                        event_id:@_id
                    Meteor.users.update Meteor.userId(),
                        $inc:points:-Session.get('point_paying')
                    Meteor.users.update @_author_id, 
                        $inc:points:Session.get('point_paying')
                    Swal.fire(
                        position: 'top-end',
                        icon: 'success',
                        title: 'ticket purchased',
                        showConfirmButton: false,
                        timer: 1500
                    )
            )
        
        'click .return': (e,t)->
            # val = parseInt $('.point_input').val()
            # Session.set('point_paying',val)
            # $('.ui.modal').modal('show')
            Swal.fire({
                title: "return ticket?"
                # text: "#{Template.parentData().title}"
                icon: 'question'
                # input:'number'
                confirmButtonText: 'return'
                confirmButtonColor: 'orange'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    Docs.remove @_id
                    Swal.fire(
                        position: 'top-end',
                        icon: 'success',
                        title: 'ticket returned',
                        showConfirmButton: false,
                        timer: 1500
                    )
            )
    
        'click .buy_for_usd': (e,t)->
            console.log Template.instance()
            val = parseInt t.$('.usd_input').val()
            Session.set('usd_paying',val)

            instance = Template.instance()

            Swal.fire({
                # title: "buy ticket for $#{@usd_price} or more!"
                title: "buy ticket for $#{Session.get('usd_paying')}?"
                text: "for #{@title}"
                icon: 'question'
                showCancelButton: true,
                confirmButtonText: 'purchase'
                # input:'number'
                confirmButtonColor: 'green'
                showCancelButton: true
                cancelButtonText: 'cancel'
                reverseButtons: true
            }).then((result)=>
                if result.value
                    # Session.set('topup_amount',5)
                    # Template.instance().checkout.open
                    instance.checkout.open
                        name: 'One Boulder One'
                        # email:Meteor.user().emails[0].address
                        description: "#{@title} ticket purchase"
                        amount: Session.get('usd_paying')*100
            
                    # Meteor.users.update @_author_id,
                    #     $inc:credit:@order_price
                    # Swal.fire(
                    #     'topup initiated',
                    #     ''
                    #     'success'
                    # )
            )




    
    Template.attendance.events
        'click .mark_maybe': ->
            event = Docs.findOne Router.current().params.doc_id
            # console.log 'hi'
            # Meteor.call 'mark_maybe', Router.current().params.doc_id, ->
            # event = Docs.findOne event_id
            if event.maybe_ids
                if Meteor.userId() in event.maybe_ids
                    Docs.update event._id,
                        $pull:
                            maybe_ids: Meteor.userId()
                else
                    Docs.update event._id,
                        $addToSet:
                            maybe_ids: Meteor.userId()
                        $pull:
                            going_ids: Meteor.userId()
                            not_going_ids: Meteor.userId()
            else
                Docs.update event._id,
                    $addToSet:
                        maybe_ids: Meteor.userId()
                    $pull:
                        going_ids: Meteor.userId()
                        not_going_ids: Meteor.userId()

        'click .mark_not': ->
            event = Docs.findOne Router.current().params.doc_id
            Meteor.call 'mark_not', Router.current().params.doc_id, ->
        'click .mark_going': -> Meteor.call 'mark_going', @_id, ->

    Template.event_card.events
        'click .mark_maybe': -> Meteor.call 'mark_maybe', @_id, ->
        'click .mark_not': -> Meteor.call 'mark_not', @_id, ->
        'click .mark_going': -> Meteor.call 'mark_going', @_id, ->
    Template.event_layout.helpers
        tickets_left: ->
            ticket_count = 
                Docs.find({ 
                    model:'transaction'
                    transaction_type:'ticket_purchase'
                    event_id: Router.current().params.doc_id
                }).count()
            @max_attendees-ticket_count



if Meteor.isServer
    Meteor.publish 'event_tickets', (event_id)->
        Docs.find
            model:'transaction'
            transaction_type:'ticket_purchase'
            event_id:event_id


    Meteor.methods
        'mark_not': (event_id)->
            event = Docs.findOne event_id
            if event.not_going_ids and Meteor.userId() in event.not_going_ids
                Docs.update event_id,
                    $pull:
                        not_going_ids: Meteor.userId()
            else
                Docs.update event_id,
                    $addToSet:
                        not_going_ids: Meteor.userId()
                    $pull:
                        going_ids: Meteor.userId()
                        maybe_ids: Meteor.userId()
    
            
        'mark_maybe': (event_id)->
            event = Docs.findOne event_id
            if event.maybe_ids and Meteor.userId() in event.maybe_ids
                Docs.update event_id,
                    $pull:
                        maybe_ids: Meteor.userId()
            else
                Docs.update event_id,
                    $addToSet:
                        maybe_ids: Meteor.userId()
                    $pull:
                        going_ids: Meteor.userId()
                        not_going_ids: Meteor.userId()
        'mark_going': (event_id)->
            event = Docs.findOne event_id
            if event.going_ids and Meteor.userId() in event.going_ids
                Docs.update event_id,
                    $pull:
                        going_ids: Meteor.userId()
            else
                Docs.update event_id,
                    $addToSet:
                        going_ids: Meteor.userId()
                    $pull:
                        maybe_ids: Meteor.userId()
                        not_going_ids: Meteor.userId()

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
    Router.route '/event/:doc_id/checkins', (->
        @layout 'event_layout'
        @render 'doc_checkins'
        ), name:'doc_checkins'
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

    Template.event_tasks.onCreated ->
        @autorun => Meteor.subscribe 'event_tasks_by_id',Router.current().params.doc_id, ->
    Template.event_tasks.helpers 
        event_task_docs: ->
            Docs.find 
                model:'task'
                parent_id:Router.current().params.doc_id
        adding_doc: ->
            Docs.findOne Session.get('viewing_quickadd')
    Template.event_tasks.events
        'click .add_event_task': ->
            if Session.get('viewing_quickadd')
                Session.set('viewing_quickadd',false)
            else 
                new_task_id = 
                    Docs.insert 
                        model:'task'
                        event_id:Router.current().params.doc_id
                        parent_id:Router.current().params.doc_id
                Session.set('viewing_quickadd',new_task_id)
                        
            
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
                
if Meteor.isServer 
    Meteor.publish 'event_tasks_by_id', (doc_id)->
        Docs.find 
            model:'task'
            event_id:doc_id