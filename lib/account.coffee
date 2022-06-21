if Meteor.isClient
    Router.route '/user/:user_id/edit', (->
        @layout 'layout'
        @render 'account'
        ), name:'account'

    Template.account.onCreated ->
        @autorun -> Meteor.subscribe 'user_from_id', Router.current().params.user_id

    Template.account.onRendered ->
        Meteor.setTimeout ->
            $('.button').popup()
        , 2000
    
    Template.account.helpers
        user_from_user_id_param: ->
            console.log 'hi'
            Meteor.users.findOne Router.current().params.user_id
    Template.account.events
        'click .remove_user': ->
            if confirm "confirm delete #{@username}?  cannot be undone."
                Meteor.users.remove @_id
                Router.go "/users"
        'click .clear_session': (e)->
            user = Meteor.users.findOne username:Router.current().params.username
            console.log @
            console.log user.services.resume.loginTokens
            $(e.currentTarget).closest('.item').transition('fly left', 500)
            Meteor.setTimeout =>
                Meteor.users.update Meteor.userId(),
                    $pull:
                        "services.resume.loginTokens":@
            , 500
    Template.account.onRendered ->
        Meteor.setTimeout ->
            $('.ui.accordion').accordion()
        , 2000