from dash import Dash, html, dash_table, dcc, callback, Output, Input
import pandas as pd
import plotly.express as px

app = Dash(__name__)

# Read the data files
df = pd.read_csv('/usr/src/app/src/mv_agg_amounts_dds.csv')
new_df = pd.read_csv('/usr/src/app/src/mv_agg_forecast.csv')

# App layout
app.layout = html.Div([ 
    html.Div(children='Agg Analyse Data'),
    
    # First Table and Graph
    html.Div(children='First Table and Graph'),
    dcc.Dropdown(id='agg-level-dropdown', options=[{'label': val, 'value': val} for val in df['agg_level'].unique() if pd.notna(val)], multi=True, placeholder='Select agg_level', value=['t_date, service_category, payer']),
    dcc.Dropdown(id='t-date-dropdown', options=[{'label': val, 'value': val} for val in df['t_date'].unique() if pd.notna(val)], multi=True, placeholder='Select t_date'),
    dcc.Dropdown(id='service-category-dropdown', options=[{'label': val, 'value': val} for val in df['service_category'].unique() if pd.notna(val)], multi=True, placeholder='Select service_category'),
    dcc.Dropdown(id='payer-dropdown', options=[{'label': val, 'value': val} for val in df['payer'].unique() if pd.notna(val)], multi=True, placeholder='Select payer'),
    dash_table.DataTable(
        id='filterable-table',
        columns=[{'name': col, 'id': col} for col in df.columns],
        data=df.to_dict('records'),
        filter_action='native',
        sort_action='native',
        page_size=7
    ),
    dcc.RadioItems(
        id='graph-radio',
        options=[
            {'label': 'Sum Paid Amount', 'value': 'sum_paid_amount'},
            {'label': 'Categories', 'value': 'categories'},
            {'label': 'Average Category Receipt', 'value': 'avg_category_receipt'},
            {'label': 'Plus Paid Amount', 'value': 'plus_paid_amount'},
            {'label': 'Minus Paid Amount', 'value': 'minus_paid_amount'},
            {'label': 'Empty Claim Specialty', 'value': 'empty_claim_specialty'}
        ],
        value='sum_paid_amount',
        labelStyle={'display': 'block'}
    ),
    dcc.Graph(id='filtered-graph'),
    dcc.Graph(id='filtered-payer-graph'),
    
    # Second Table and Graph
    html.Div(children='Forecasts'),
    dcc.Dropdown(id='new-agg-level-dropdown', options=[{'label': val, 'value': val} for val in new_df['agg_level'].unique() if pd.notna(val)], multi=True, placeholder='Select agg_level', value=['t_date, payer']),
    dcc.Dropdown(id='new-t-date-dropdown', options=[{'label': val, 'value': val} for val in new_df['forecast_date'].unique() if pd.notna(val) and val >= '2020-05-01'], multi=True, placeholder='Select forecast_date'),
    dcc.Dropdown(id='new-service-category-dropdown', options=[{'label': val, 'value': val} for val in new_df['service_category'].unique() if pd.notna(val)], multi=True, placeholder='Select service_category'),
    dcc.Dropdown(id='new-payer-dropdown', options=[{'label': val, 'value': val} for val in new_df['payer'].unique() if pd.notna(val)], multi=True, placeholder='Select payer', value=['Payer CO']),
    dash_table.DataTable(
        id='new-filterable-table',
        columns=[{'name': col, 'id': col} for col in new_df.columns],
        data=new_df.to_dict('records'),
        filter_action='native',
        sort_action='native',
        page_size=7
    ),
    dcc.RadioItems(
        id='new-graph-radio',
        options=[
            {'label': 'Sum Paid Amount', 'value': 'sum_paid_amount'},
            {'label': 'Rolling Average', 'value': 'rolling_avg'},
            {'label': 'Seasonal Average', 'value': 'seasonal_avg'},
            {'label': 'Exponential Average', 'value': 'exponential_avg'},
            {'label': 'Seasonal Exponential Average', 'value': 'seasonal_exponential_avg'}
        ],
        value='sum_paid_amount',
        labelStyle={'display': 'block'}
    ),
    dcc.Graph(id='new-filtered-graph')
])

# Add controls to build the interaction for the first table and graph
@app.callback(
    Output('filterable-table', 'data'),
    Output('filtered-graph', 'figure'),
    Output('filtered-payer-graph', 'figure'), 
    Input('agg-level-dropdown', 'value'),
    Input('t-date-dropdown', 'value'),
    Input('service-category-dropdown', 'value'),
    Input('payer-dropdown', 'value'),
    Input('graph-radio', 'value')
)
def update_table_and_graph(agg_level, t_date, service_category, payer, selected_graph):
    filtered_df = df
    if agg_level:
        filtered_df = filtered_df[filtered_df['agg_level'].isin(agg_level)]
    if t_date:
        filtered_df = filtered_df[filtered_df['t_date'].isin(t_date)]
    if service_category:
        filtered_df = filtered_df[filtered_df['service_category'].isin(service_category)]
    if payer:
        filtered_df = filtered_df[filtered_df['payer'].isin(payer)]
    
    # Create graphs based on filtered data
    if selected_graph == 'sum_paid_amount':
        fig = px.bar(filtered_df, x='t_date', y='sum_paid_amount', color='service_category')
    elif selected_graph == 'categories':
        fig = px.bar(filtered_df, x='t_date', y='categories', color='service_category')
    elif selected_graph == 'avg_category_receipt':
        fig = px.bar(filtered_df, x='t_date', y='avg_category_receipt', color='service_category')
    elif selected_graph == 'plus_paid_amount':
        fig = px.bar(filtered_df, x='t_date', y='plus_paid_amount', color='service_category')
    elif selected_graph == 'minus_paid_amount':
        fig = px.bar(filtered_df, x='t_date', y='minus_paid_amount', color='service_category')
    elif selected_graph == 'empty_claim_specialty':
        fig = px.bar(filtered_df, x='t_date', y='empty_claim_specialty', color='service_category')
    
    # Create a second bar graph based on payer
    payer_fig = px.bar(filtered_df, x='t_date', y=selected_graph, color='payer')
    
    return filtered_df.to_dict('records'), fig, payer_fig

# Add controls to build the interaction for the second table and graph
@app.callback(
    Output('new-filterable-table', 'data'),
    Output('new-filtered-graph', 'figure'),
    Input('new-agg-level-dropdown', 'value'),
    Input('new-t-date-dropdown', 'value'),
    Input('new-service-category-dropdown', 'value'),
    Input('new-payer-dropdown', 'value'),
    Input('new-graph-radio', 'value')
)
def update_new_table_and_graph(agg_level, t_date, service_category, payer, selected_graph):
    filtered_df = new_df
    if agg_level:
        filtered_df = filtered_df[filtered_df['agg_level'].isin(agg_level)]
    if t_date:
        filtered_df = filtered_df[filtered_df['forecast_date'].isin(t_date)]
    if service_category:
        filtered_df = filtered_df[filtered_df['service_category'].isin(service_category)]
    if payer:
        filtered_df = filtered_df[filtered_df['payer'].isin(payer)]
    
    # Create graphs based on filtered data
    fig = px.bar(filtered_df, x='forecast_date', y=selected_graph, color='service_category')
    
    # Add line plot with sum_paid_amount values
    if 'sum_paid_amount' not in selected_graph:
        line_fig = px.line(filtered_df, x='forecast_date', y='sum_paid_amount', color='service_category')
        fig.add_trace(line_fig.data[0])
    
    return filtered_df.to_dict('records'), fig

if __name__ == '__main__':
    app.run_server(host='0.0.0.0', port=8050, debug=True)