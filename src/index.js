Vue = require('vue')
axios = require('axios')

Vue.component('favorite',{
  props: {
    eventid: {
              type: Number, 
              default: 0,                         
             },
    isfavorite: {
      type: Boolean,
      default: false
    },
    msg: {
      type: String,
      default: "登録"
    },
    isactive: {
      type: Boolean,
      default: true
    }
  },
  methods: {
    post(){ 
      config = {
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'Content-Type': 'application / x-www-form-urlencoded'
        },
        withCredentials: true,
      }
      console.log(this.eventid);
      params = new URLSearchParams()
      params.append('eventid',this.eventid)

      if(this.isactive && !this.isfavorite){
        url = 'http://118.27.16.67/p-schedule/favorite/new'
        axios.post(url, params, config)
        .then(res => {
          this.isactive = false
          this.isfavorite = true
          this.msg = "解除"
          console.log(res)
        })
        .catch(res => {
          //vueにバインドされている値を書き換えると表示に反映される
          console.log(res)
        })
      }  
      else if(!this.isactive && this.isfavorite){
        url = 'http://118.27.16.67/p-schedule/favorite/delete'
        axios.post(url, params, config)
        .then( res =>  {
          this.isactive = true
          this.isfavorite = false
          this.msg = "登録"
        })
        .catch( res =>  {
          //vueにバインドされている値を書き換えると表示に反映される
          console.log(res)
        })
      }     
      
      console.log(url)

      
        
    }    
  },
  template: `<button 
                type="button" 
                class='btn'
                v-bind:class="{ 'btn-secondary': isactive, 'btn-success': isfavorite }"

                v-on:click="post">
                  {{msg}}
              </button>`
}
)

Vue.component('bought',{
  props: {
    eventid: {
              type: Number, 
              default: 0,                         
             },
    isbought: {
      type: Boolean,
      default: false
    },
    msg: {
      type: String,
      default: "登録"
    },
    isactive: {
      type: Boolean,
      default: true
    }
  },
  methods: {
    post(){ 
      config = {
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'Content-Type': 'application / x-www-form-urlencoded'
        },
        withCredentials: true,
      }
      console.log(this.eventid);
      params = new URLSearchParams()
      params.append('eventid',this.eventid)

      if(this.isactive && !this.isbought){
        url = 'http://118.27.16.67/p-schedule/bought/new'
        axios.post(url, params, config)
        .then(res => {
          this.isactive = false
          this.isbought = true
          this.msg = "解除"
          console.log(res)
        })
        .catch(res => {
          //vueにバインドされている値を書き換えると表示に反映される
          console.log(res)
        })
      }  
      else if(!this.isactive && this.isbought){
        url = 'http://118.27.16.67/p-schedule/bought/delete'
        axios.post(url, params, config)
        .then( res =>  {
          this.isactive = true
          this.isbought = false
          this.msg = "登録"
        })
        .catch( res =>  {
          //vueにバインドされている値を書き換えると表示に反映される
          console.log(res)
        })
      }     
      
      console.log(url)  
    }    
  },
  template: `<button 
                type="button" 
                class='btn'
                v-bind:class="{ 'btn-secondary': isactive, 'btn-success': isbought }"

                v-on:click="post">
                  {{msg}}
              </button>`
}
)

new Vue({
  el: '.app',
})
