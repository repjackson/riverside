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
            
    Template.event_edit.onCreated ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.event_layout.onCreated ->
        # @autorun => Meteor.subscribe 'product_from_transfer_id', Router.current().params.doc_id, ->
        @autorun => Meteor.subscribe 'author_from_doc_id', Router.current().params.doc_id, ->
        @autorun => Meteor.subscribe 'doc_by_id', Router.current().params.doc_id, ->
    Template.event_section.helpers
        section_template: -> "event_#{Router.current().params.section}"
