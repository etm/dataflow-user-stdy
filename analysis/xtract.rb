#!/usr/bin/ruby
require 'json'
require 'fileutils'
require 'yaml'
require 'date'
require 'csv'

def get_scales(what,io,num) #{{{
  yaml = YAML.load_stream io

  begin
    find = yaml.shift
  end until find.dig('event','cpee:lifecycle:transition') == 'activity/calling' && find.dig('event','concept:name') == what
  start = Time.parse(find.dig('event','time:timestamp'))
  begin
    find = yaml.shift
  end until find.dig('event','cpee:lifecycle:transition') == 'activity/receiving' && find.dig('event','concept:name') == what
  duration = Time.parse(find.dig('event','time:timestamp')) - start

  dat = JSON::parse(find.dig('event','data',0,'data'))
  if dat.length < num
    dat = []
  else
    dat = dat.first.map{|k,v| k}
  end

  io.rewind
  [duration,dat]
end #}}}

def get_buttons(what,io) #{{{
  yaml = YAML.load_stream io

  begin
    find = yaml.shift
  end until find.dig('event','cpee:lifecycle:transition') == 'activity/calling' && find.dig('event','concept:name') == what
  start = Time.parse(find.dig('event','time:timestamp'))
  begin
    find = yaml.shift
  end until find.dig('event','cpee:lifecycle:transition') == 'activity/receiving' && find.dig('event','concept:name') == what
  duration = Time.parse(find.dig('event','time:timestamp')) - start

  dat = JSON::parse(find.dig('event','data',0,'data'))
  if dat.empty?
    data = []
  else
    dat = dat.first.last.filter{ |k,v| v }.map{|k,v| k}
  end

  io.rewind
  [duration,dat.sort.join(',')]
end #}}}

def get_select(what,io) #{{{
  yaml = YAML.load_stream io

  begin
    find = yaml.shift
  end until find.dig('event','cpee:lifecycle:transition') == 'activity/calling' && find.dig('event','concept:name') == what
  start = Time.parse(find.dig('event','time:timestamp'))
  begin
    find = yaml.shift
  end until find.dig('event','cpee:lifecycle:transition') == 'activity/receiving' && find.dig('event','concept:name') == what
  duration = Time.parse(find.dig('event','time:timestamp')) - start

  dat = JSON::parse(find.dig('event','data',0,'data'))
  if dat.empty?
    dat = ''
  else
    dat = dat.first.last
  end

  io.rewind
  [duration,dat]
end #}}}

def get_name(io) #{{{
  yaml = YAML.load_stream io

  begin
    find = yaml.shift
  end until find.dig('event','cpee:lifecycle:transition') == 'dataelements/change'
  data = find.dig('event','data')
  complex = data.dig(1,'value','time')
  complex = case complex
    when 30; 'simple'
    when 35; 'medium'
    when 40; 'complex'
  end

  io.rewind
  return [
    data.dig(1,'value','bpmn_task'),
    data.dig(1,'value','cpee_task'),
    complex
  ]
end #}}}

results = CSV.open('results.csv','wb')
satis = CSV.open('satisfaction.csv','wb')

Dir.glob('finished/*.xes.yaml') do |f|
  io = File.open f
  yaml = YAML.load_stream io
  first = yaml.shift
  io.rewind
  p f

  if first.dig('log','trace','cpee:name') == 'QuestSub'
    bpmn, cpee, complex = get_name io
    item1 = ['BPMN',bpmn,complex]
    item2 = ['CPEE',cpee,complex]
    item3 = [bpmn,cpee,complex]

    item1 << get_buttons('BPMN Simple Questions 0', io) rescue []
    item1 << get_buttons('BPMN Simple Questions 1', io) rescue []
    item1 << get_buttons('BPMN Simple Questions 2', io) rescue []
    item1 << get_buttons('BPMN Simple Questions 3', io) rescue []
    item1 << get_select( 'BPMN Simple Questions 4', io) rescue []

    item2 << get_buttons('CPEE Simple Questions 0', io) rescue []
    item2 << get_buttons('CPEE Simple Questions 1', io) rescue []
    item2 << get_buttons('CPEE Simple Questions 2', io) rescue []
    item2 << get_buttons('CPEE Simple Questions 3', io) rescue []
    item2 << get_select( 'CPEE Simple Questions 4', io) rescue []

    item3 << get_scales( 'Final Questions', io, 3) rescue []

    results << item1.flatten
    results << item2.flatten

    satis << item3.flatten
  end
  io.close
end

results.close
satis.close


